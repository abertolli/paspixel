{ This code was written by and donated to the Graphics File Formats }
{ page by Maris, e-mail: <v1vpub@lasis.valmiera.lanet.lv>           }
{ ----                                                              }
{ Martin Reddy, the Graphics File Formats page:                     }
{ <http://www.dcs.ed.ac.uk/~mxr/gfx                                 }
{$MODE TP}
{$ASMMODE INTEL}

unit BMP;

Interface
Procedure load_bmp(x,y:integer; filename:string);
Procedure save_bmp(x1,y1,x2,y2:integer;filename:string;bitmap:byte);
{Bitmap is "bit4" or "bit8"}

Implementation
Uses Crt,Dos,Graph,ports;

var x,y,mk,xx1,yy1:integer;
rgbb:palettetype;
WholePal : Array[1..256,1..3] of Byte;
f:file of byte;
regs:registers;
  maxx,maxy,p       :integer;
  f1                     :file;
  header                :record
                           bm:array[0..1] of char;
                           groottebestand       :longint;
                           reserve              :longint;
                           offset               :longint;
                           groottebeeldinfo     :longint;
                         end;
  beeldinfo             :record
                           breedte,hoogte       :longint;
                           vlakken,bitsperpixel :word;
                           hor,ver              :longint;
                           aantalkleuren        :longint;
                         end;
  bytesperlijn,oudpos   :longint;
  rgbi                  :array[1..256] of record bb,gg,rr,ii :byte;end;
  rgb                   :array[1..256] of record r,g,b :byte;end;
  lijn                  :array[1..1024] of byte;
  gd,gm:integer;


const
bit8=0;
bit4=1;


function Int(I: Longint): String;{Converts integer to string}
var s:string;
begin
str(I,S);
int:=S;
end;


Procedure load_bmp(x,y:integer; filename:string);
var f:file of byte;
b,b1,value:byte;
pix1,pix2,xx,yy:integer;
heigh,width,sakums:word;
w:word;

Procedure ByteToHex(byt:byte; var hex1,hex2:integer);
{Converts Byte to Hexdecimal number}
var
atl,dal,code:integer;
ss1,ss2:string;
begin
atl:=byt mod 16;
dal:=(byt-atl) div 16;
ss1:=int(dal);
ss2:=int(atl);
val(ss1,hex1,code);
val(ss2,hex2,code);
end;

procedure set256palette(var rgb_buffer);{Sets 256 color palette}
begin
  with regs do begin
    ax :=$1012;
    bx :=0;
    cx :=256;
    es :=seg(rgb_buffer);
    dx :=ofs(rgb_buffer);
    intr($10,regs);
  end;
end;


Procedure load_bmp_16(x,y:integer; filename:string);
var
x1,y1:integer;
begin
seek(f,sakums);
for y1:=heigh downto 1 do
    for x1:=1 to width do
        begin
        read(f,b);
        byteToHex(b,pix1,pix2);
        putpixel(x1+x,y1+y,pix1);
        inc(x1);
        putpixel(x1+x,y1+y,pix2);
        end;
end;



procedure load_bmp_256(xx,yy :integer;filename :string);
var
x,y:integer;
begin
  maxx :=getmaxx-1;maxy :=getmaxy-1;
  assign(f1,filename);
  {$I-} reset(f1,1); {$I+}
  if ioresult =0 then begin
    blockread(f1,header,sizeof(header));
    fillchar(beeldinfo,sizeof(beeldinfo),0);
    blockread(f1,beeldinfo,header.groottebeeldinfo -4);
    with beeldinfo,header do begin
      bytesperlijn :=breedte *bitsperpixel;
      if (bytesperlijn and 31) =0 then bytesperlijn :=bytesperlijn shr 3
        else bytesperlijn :=succ(bytesperlijn shr 5)shl 2;
      if aantalkleuren =0 then aantalkleuren :=1 shl bitsperpixel;
      if bitsperpixel <>8 then
         begin
         halt;
         end;
      blockread(f1,rgbi,4*aantalkleuren);
      for p :=1 to aantalkleuren do with rgb[p],rgbi[p] do begin
        r :=rr shr 2;
        g :=gg shr 2;
        b :=bb shr 2;
      end;
      set256palette(rgb);
      with header,beeldinfo do begin
        if hoogte <= maxy then oudpos :=offset
          else oudpos :=offset +bytesperlijn *(hoogte -maxy);
        if breedte < maxx then maxx :=breedte;
        if hoogte <maxy then maxy :=hoogte;
        for y:=yy+(maxy-1) downto yy do begin
          seek(f1,oudpos);
          blockread(f1,lijn,maxx);
          for x :=xx to (maxx)+xx do putpixel(x,y,lijn[x-xx]);
        if eof(f1) then exit;
          inc(oudpos,bytesperlijn);
        end;
      end;
      close(f1);
    end;
  end;
end;

begin
assign(f,filename);
reset(f);
seek(f,$12);
read(f,b1);
read(f,b);
asm
mov ah,b
mov al,b1
mov [width],ax {Converts two bytes to one word}
end;

seek(f,$16);
read(f,b1);
read(f,b);
asm
mov ah,b
mov al,b1
mov [heigh],ax
end;

seek(f,$0A);
read(f,b);
read(f,b1);
asm
mov ah,b1
mov al,b
mov [sakums],ax
end;
seek(f,$1C);
read(f,value);
case value of
     4: load_bmp_16(x,y,filename);
     8: load_bmp_256(x,y,filename);
     else exit;
end;
close(f);
end;





procedure HexToDec(hex:string; var byt:byte);
var ss1,ss2:string;
byt1,byt2:byte;
code:integer;

begin
ss1:=hex[1]+hex[2];
ss2:=hex[3]+hex[4];
val(ss1,byt1,code);
val(ss2,byt2,code);
byt1:=byt1*16;
byt:=byt1+byt2;
end;


procedure save_bmp(x1,y1,x2,y2:integer;filename:string;bitmap:byte);

procedure save_bmp_4bit(x1,y1,x2,y2:integer; filename:string);
var
f:file of byte;
b,b1:byte;
w:word;
f2:file of word;
bb,bb1,bb2,bbb1,bbb2:string;
x,y,i:integer;
r,g:byte;
begin

assign(f2,filename);
rewrite(f2);
reset(f2);
seek(f2,$12 div 2);
w:=x2-x1;
write(f2,w);

seek(f2,$16 div 2);
w:=y2-y1;
write(f2,w);
close(f2);

assign(f,filename);
reset(f);

seek(f,0);
b:=0;
for i:=1 to $11 do
write(f,b);

seek(f,$18);
for i:=$18 to $76 do
write(f,b);

seek(f,0);
b:=ord('B');
write(f,b);

seek(f,1);
b:=ord('M');
write(f,b);

seek(f,$08);
b:=0;
write(f,b);
write(f,b);
seek(f,$0A);
b:=$76;
write(f,b);
seek(f,$0E);
b:=$28;
write(f,b);

seek(f,$1A);
b:=$01;
write(f,b);

seek(f,$1C);
b:=$04;
write(f,b);

seek(f,$36);
b:=0;
write(f,b);
write(f,b);
write(f,b);
b:=0;
write(f,b);


b:=128;
write(f,b);
b:=0;
write(f,b);
write(f,b);
b:=0;
write(f,b);

b:=0;
write(f,b);
b:=128;
write(f,b);
b:=0;
write(f,b);
b:=0;
write(f,b);

b:=128;
write(f,b);
write(f,b);
b:=0;
write(f,b);
b:=0;
write(f,b);

b:=0;
write(f,b);
write(f,b);
b:=128;
write(f,b);
b:=0;
write(f,b);

b:=128;
write(f,b);
b:=0;
write(f,b);
b:=128;
write(f,b);
b:=0;
write(f,b);

b:=64;
write(f,b);
b:=128;
write(f,b);
write(f,b);
b:=0;
write(f,b);

b:=192;
write(f,b);
write(f,b);
write(f,b);
b:=0;
write(f,b);

b:=128;
write(f,b);
write(f,b);
write(f,b);
b:=0;
write(f,b);

b:=255;
write(f,b);
b:=0;
write(f,b);
write(f,b);
b:=0;
write(f,b);

b:=0;
write(f,b);
b:=255;
write(f,b);
b:=0;
write(f,b);
b:=0;
write(f,b);


b:=255;
write(f,b);
write(f,b);
b:=0;
write(f,b);
b:=0;
write(f,b);

b:=0;
write(f,b);
write(f,b);
b:=255;
write(f,b);
b:=0;
write(f,b);

b:=255;
write(f,b);
b:=0;
write(f,b);
b:=255;
write(f,b);
b:=0;
write(f,b);

b:=0;
write(f,b);
b:=255;
write(f,b);
write(f,b);
b:=0;
write(f,b);

b:=255;
write(f,b);
write(f,b);
write(f,b);
b:=0;
write(f,b);

seek(f,$76);
i:=0;
y:=y2;
repeat
x:=x1;
repeat
    b:=getpixel(x,y);
    inc(x);
    b1:=getpixel(x,y);
    bb1:=int(b);
    bb2:=int(b1);
    if length(bb1)=1 then begin bbb1:=bb1; bb1[1]:='0'; bb1:=bb1+bbb1; end;
    if length(bb2)=1 then begin bbb2:=bb2; bb2[1]:='0'; bb2:=bb2+bbb2; end;
    bb:=bb1+bb2;
    HexToDec(bb,b);
    write(f,b);
    inc(x);
until x>=x2;
dec(y);
until y<=y1;
close(f);
end;

Procedure GetPal(ColorNo : Byte; Var R,G,B : Byte);
  { This reads the values of the Red, Green and Blue values of a certain
    color and returns them to you. }
Begin
   Port[$3C7] := ColorNo;
   R := Port[$3C8];{You can put in all of numbers $3C8 number $3C9 and
                   then it will get palette with maximum 63 digits each color}
   G := Port[$3C8]; {I can't find Port, to read color palette}
   B := Port[$3C8]; {Thats the Port of 8 bit grayscale!}
End;                {If You know, wich port is the right to read all
                    palette with all its colors, E-Mail me and send this
                    Port number - PLEASE!}



procedure save_bmp_8bit(x1,y1,x2,y2:integer; filename:string);
var
byt1,byt2,rrr,ggg,bbb:byte;
f:file of byte;
b,b1,b3:byte;
w,sakums:word;
f2:file of word;
bb,bb1,bb2,bbb1,bbb2:string;
l:longint;
x,y,xx,yy,i,j,col:integer;
r,g:byte;

begin
assign(f2,filename);
rewrite(f2);
reset(f2);
seek(f2,$12 div 2);
w:=x2-x1;
write(f2,w);

seek(f2,$16 div 2);
w:=y2-y1;
write(f2,w);
close(f2);

assign(f,filename);
reset(f);

seek(f,0);
b:=0;
for i:=1 to $11 do
write(f,b);

seek(f,$18);
for i:=$18 to $76 do
write(f,b);

seek(f,0);
b:=ord('B');
write(f,b);

seek(f,1);
b:=ord('M');
write(f,b);

seek(f,$08);
b:=0;
write(f,b);
write(f,b);
seek(f,$0A);
b:=$76;
write(f,b);
seek(f,$0E);
b:=$28;
write(f,b);

seek(f,$1A);
b:=$01;
write(f,b);

seek(f,$1C);
b:=16;
write(f,b);

seek(f,$1C);
b:=8;
write(f,b);

seek(f,$36);
b1:=$00;
for i:=0 to 255 do
    begin
    getpal(i,r,g,b);
    write(f,b,g,r,b1);
    end;

seek(f,$A);
b:=$36;
write(f,b);
b:=$04;
write(f,b);

seek(f,$A);
read(f,b,b1);

asm
mov ah,b1
mov al,b
mov [sakums],ax {Converts two bytes to one word}
end;

seek(f,sakums);
for y:=y2 downto y1 do
for x:=x1+1 to x2 do
    begin
    b:=getpixel(x,y);
    write(f,b);
    end;
close(f);
end;

begin
case bitmap of
     bit4:save_bmp_4bit(x1,y1,x2,y2,filename);
     bit8:save_bmp_8bit(x1,y1,x2,y2,filename);
end;
end;

{If You know, wich port is the right to read all
palette with all its colors (each color 256 digits of palette),
E-Mail me and send this Port number - PLEASE!}
{Maybe you know another way how to read current palette?
 Then E-Mail me! (Maris: e-mail at top of file)}
end.


program BMPtoLN;

uses crt, graph;

var
     device    :     integer;
     mode      :     integer;
     ch        :     char;
     bmpfile   :     string;
     lnfile    :     string;
     xsize     :     integer;
     ysize     :     integer;
     lineoftext:     string[80];

{--------------------------------------------------------------------------}
procedure graph_init(var gdriver,gmode:integer;gpath:string);

var
     error          :    integer;

begin
     writeln;
     DetectGraph(gdriver,gmode);

     gdriver:=vga;
     gmode:=vgahi;

     initgraph(gdriver,gmode,gpath);
     error:=graphresult;
     if not(error=grOK)then
          begin
               writeln('Graphics initialization error!');
               writeln('Program cannot continue.  Press enter.');
               readln;
               halt(1);
          end;
end;

{--------------------------------------------------------------------------}
function readjust(c:integer):integer;

begin

   case c of
      lightgray     :readjust:=darkgray;
      darkgray      :readjust:=lightgray;
      blue          :readjust:=red;
      lightblue     :readjust:=lightred;
      cyan          :readjust:=brown;
      lightcyan     :readjust:=yellow;
      brown         :readjust:=cyan;
      yellow        :readjust:=lightcyan;
      red           :readjust:=blue;
      lightred      :readjust:=lightblue;
   else
      readjust:=c;

   end; {case}

end;
{--------------------------------------------------------------------------}
procedure drawbmp16(dosname:string;xpos,ypos:integer);

type
     FileHeader    = record
                        bfType        : word;
                        bfSize        : longint;
                        bfReserved1   : word;
                        bfReserved2   : word;
                        bfOffBits     : longint;
     end;

     InfoHeader = record
                     biSize           : longint;
                     biWidth          : longint;
                     biHeight         : longint;
                     biPlanes         : word;
                     biBitCount       : word;
                     biCompression    : longint;
                     biSizeImage      : longint;
                     biXPelsPerMeter  : longint;
                     biYPelsPerMeter  : longint;
                     biClrUsed        : longint;
                     biClrImportant   : longint;
     end;

     Quad = record
               blue                   : byte;
               green                  : byte;
               red                    : byte;
               Reserved               : byte;
     end;

     TBitmapInfo = record
                      bmiFileheader   : FileHeader;
                      bmiHeader       : InfoHeader;
                      bmiColors       : array[0..15] of Quad;
     end;

var
     f     :     file of byte;
     info  :     file of TbitmapInfo;
     data  :     TbitmapInfo;
     color :     integer;
     b     :     byte;
     x     :     word;
     y     :     word;

begin

     assign(info,dosname);
     reset(info);
     read(info,data);
     close(info);

     assign(f,dosname);
     reset(f);
     seek(f,data.bmifileheader.bfoffbits);

     for y:=data.bmiheader.biheight downto 1 do
          for x:=1 to (data.bmiheader.biwidth div 2+3) and not 3  do
               begin
                    read(f,b);
                    color:=b shr 4;
                    putpixel((x*2)+xpos,y+ypos,readjust(color));
                    color:=b and 15;
                    putpixel((x*2)+1+xpos,y+ypos,readjust(color));
               end;

     close(f);

end;
{---------------------------------------------------------------------------}
procedure STOREPICTUREBYLINE(beginx,beginy,endx,endy:integer;dosname:string;
                       whiteout:boolean);

{dosname            =    name of the file, including extention
beginx, beginy      =    the coordinates of where the upper left hand corner
                         of the picture
endx, endy          =    lower right hand corner of the picture
whiteout            =    TRUE means that the picture area will become white
                         as it is stored}

var
     pasfile        :    text;
     row            :    integer;
     col            :    integer;
     color          :    integer;
     length         :    integer;
     nextcolor      :    integer;

begin
     assign(pasfile,dosname);
     rewrite(pasfile);
     writeln(pasfile,'FORMAT=LINE');
     for row:=beginy to endy do
          begin
               length:=0;
               for col:=beginx to endx do
                    begin
                         color:=getpixel(col,row);
                         length:=length + 1;
                         nextcolor:=getpixel(col+1,row);
                         if(color<>nextcolor)or(col=endx)then
                              begin
                                   write(pasfile,color);
                                   write(pasfile,' ');
                                   write(pasfile,length);
                                   if(col<>endx)then
                                        write(pasfile,' ');
                                   if(whiteout)then
                                        begin
                                             setcolor(white);
                                             line(col,row,(col-length),row);
                                        end;
                                   length:=0;
                              end;
                    end;
               writeln(pasfile);
          end;
     close(pasfile);
end;
{--------------------------------------------------------------------------}
procedure DRAWPICTUREBYLINE(beginx,beginy:integer;dosname:string);

{dosname            =    name of the file, including extention
beginx, beginy      =    the coordinates of where the upper left hand corner
                         of where the picture will be.}

var
     pasfile        :    text;
     row            :    integer;
     col            :    integer;
     color          :    integer;
     length         :    integer;

begin

     assign(pasfile,dosname);
     reset(pasfile);
     readln(pasfile,lineoftext);
     if(lineoftext='FORMAT=LINE')then
          begin
               row:=beginy;
               col:=beginx;
               while not eof(pasfile) do
                    begin
                         while not eoln(pasfile) do
                              begin
                                   read(pasfile,color);
                                   read(pasfile,ch);
                                   read(pasfile,length);
                                   if not eoln(pasfile) then
                                        read(pasfile,ch);
                                   setcolor(color);
                                   line(col,row,(col+length),row);
                                   col:=col + length;
                              end;
                         readln(pasfile);
                         row:=row + 1;
                         col:=beginx;
                    end;
          end;
     close(pasfile);

end;
{--------------------------------------------------------------------------}

begin
          clrscr;
          textcolor(white);
          write('BMP file (input):  ');
          readln(bmpfile);
          write('x size:  ');

          readln(xsize);
          write('y size:  ');
          readln(ysize);
          writeln;
          write('LN1 file (output):  ');
          readln(lnfile);
          writeln;

          graph_init(device,mode,'c:\tp\bgi');

          drawbmp16(bmpfile,0,0);
          ch:=readkey;

          STOREPICTUREBYLINE(1,1,xsize+1,ysize+1,lnfile,true);
          DRAWPICTUREBYLINE(100,100,lnfile);

          ch:=readkey;
          closegraph;
end.

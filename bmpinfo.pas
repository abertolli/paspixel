{$A+,B-,D+,E+,F-,G-,I+,L+,N-,O-,R-,S+,V+,X-}
{$M 16384,0,655360}

program bmpinfo;

uses crt, graph, dos;

type
     TBitmapFileHeader = record
          bfType         :    word;
          bfSize         :    longint;
          bfReserved1    :    word;
          bfReserved2    :    word;
          bfOffBits      :    longint;
     end;

     TBitmapInfoHeader = record
          biSize         :    longint;
          biWidth        :    longint;
          biHeight       :    longint;
          biPlanes       :    word;
          biBitCount     :    word;
          biCompression  :    longint;
          biSizeImage    :    longint;
          biXPelsPerMeter:    longint;
          biYPelsPerMeter:    longint;
          biClrUsed      :    longint;
          biClrImportant :    longint;
     end;

     TRGBQuad = record
          rgbblue        :    byte;
          rgbgreen       :    byte;
          rgbred         :    byte;
          rgbReserved    :    byte;
     end;

     TBitmapInfo = record
          bmiFileheader  :    TBitmapFileHeader;
          bmiHeader      :    TBitmapInfoHeader;
          bmiColors      :    array[0..15] of TRGBQuad;
     end;

var
     x,y   :     word;
     device:     integer;
     mode  :     integer;
     ch    :     char;
     loop  :     integer;

{---------------------------------------------------------------------------}
procedure GFILESLOC(var gdriver,gmode:integer;gpath:string);

var
     error          :    integer;

begin
     clrscr;
     repeat
          gdriver:=detect;
          initgraph(gdriver,gmode,gpath);
          error:=graphresult;
          if(error<>grOK)then
               begin
                    writeln('Graphics error:  ',grapherrormsg(error));
                    if(error=grfilenotfound)then
                         begin
                              writeln;
                              writeln('     Cannot find graphics driver.');
                              write('     Please enter directory path for the driver:  ');
                              readln(gpath);
                              writeln;
                         end
                    else
                         halt(1);
               end;
     until(error=grOK);
end;
{--------------------------------------------------------------------------}
procedure drawbmp(dosname:string;xpos,ypos:integer);

var
     thefile        :     file of byte;
     datafile       :     file of TbitmapInfo;
     b              :     byte;
     data           :     TbitmapInfo;

begin

     assign(datafile,dosname);
     reset(datafile);
     read(datafile,data);
     close(datafile);

     assign(thefile,dosname);
     reset(thefile);
     seek(thefile,data.bmifileheader.bfoffbits);

     {CHANGE COLOR PALETTE}
     for loop:=0 to 15 do
          begin
               setrgbpalette(loop,(data.bmicolors[loop].rgbred shr 2),
                             (data.bmicolors[loop].rgbgreen shr 2),
                             (data.bmicolors[loop].rgbblue shr 2));
               setpalette(loop,loop);
          end;

     {DRAWING PICTURE}
     for y:=data.bmiheader.biheight downto 1 do
          for x:=1 to (data.bmiheader.biwidth div 2+3) and not 3  do
               begin
                    read(thefile,b);
                    putpixel((x*2)+xpos,y+ypos,b shr 4);
                    putpixel((x*2+1)+xpos,y+ypos,b and 15);
               end;
     close(thefile);

end;
{--------------------------------------------------------------------------}
procedure getinfo(dosname:string);

var
     thefile        :     file of byte;
     datafile       :     file of TbitmapInfo;
     b              :     byte;
     data           :     TbitmapInfo;

begin

     assign(datafile,dosname);
     reset(datafile);
     read(datafile,data);
     close(datafile);

     clrscr;
     with data do
          begin
               with bmiFileheader do
                    begin
                         writeln('File Header');
                         writeln('Type: ',bfType);
                         writeln('Size: ',bfSize);
                         writeln('Reserved1: ',bfReserved1);
                         writeln('Reserved2: ',bfReserved2);
                         writeln('Off Bits: ',bfOffBits);
                    end;
               readln;
               writeln;
               writeln;
               with bmiHeader do
                    begin
                         writeln('Info Header');
                         writeln('Size: ',biSize);
                         writeln('Width: ',biWidth);
                         writeln('Height: ',biHeight);
                         writeln('Planes: ',biPlanes);
                         writeln('Bit Count: ',biBitCount);
                         writeln('Compression: ',biCompression);
                         writeln('Size Image: ',biSizeImage);
                         writeln('X Pels Per Meter: ',biXPelsPerMeter);
                         writeln('Y Pels Per Meter: ',biYPelsPerMeter);
                         writeln('Clr Used: ',biClrUsed);
                         writeln('Clr Important: ',biClrImportant);
                    end;
               readln;
               writeln;
               writeln;
               for loop:=0 to 15 do
                    with bmiColors[loop] do
                         begin
                              writeln('Colors ',loop);
                              writeln('blue: ',rgbblue);
                              writeln('green: ',rgbgreen);
                              writeln('red: ',rgbred);
                              writeln('Reserved: ',rgbReserved);
                              readln;
                              writeln;
                         end;
          end;

end;
{--------------------------------------------------------------------------}

begin
{
     gfilesloc(device,mode,'c:\programs\bgi');
     drawbmp('winlogo.bmp',100,100);
}
     getinfo('winlogo.bmp');
     ch:=readkey;
     closegraph;
end.
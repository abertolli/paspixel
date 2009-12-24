program BMPViewer;

{This attempts to view native MS Paint 4-bit BMP files without
 changing the palette.}

uses crt, graph;

var
     device    :     integer;
     mode      :     integer;
     ch        :     char;
     bmpfile   :     string;

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
{--------------------------------------------------------------------------}

begin
          clrscr;
          writeln('black ',black);
          writeln('white ',white);
          writeln('red ',red);
          writeln('blue ',blue);
          writeln('green ',green);
          writeln('magenta ',magenta);
          writeln('yellow ',yellow);
          writeln('brown ',brown);
          writeln('lightred ',lightred);
          writeln('lightblue ',lightblue);
          writeln('lightgreen ',lightgreen);
          writeln('lightmagenta ',lightmagenta);
          writeln('cyan ',cyan);
          writeln('lightcyan ',lightcyan);
          writeln('lightgray ',lightgray);
          writeln('darkgray ',darkgray);

          write('4-bit BMP file:  ');
          readln(bmpfile);

          graph_init(device,mode,'c:\tp\bgi');

          drawbmp16(bmpfile,0,0);
          ch:=readkey;
          closegraph;
end.

{
MS Paint -> Pascal

black          -> black
white          -> white
dark gray      -> light gray
light gray     -> dark gray
red            -> blue
light red      -> light blue
dark yellow    -> cyan
yellow         -> light cyan
green          -> green
light green    -> light green
cyan           -> brown
light cyan     -> yellow
blue           -> red
light blue     -> light red
magenta        -> magenta
light magenta  -> light magenta

}

program LNtoBMP;

uses bmp, crt, graph;

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
function GetLNSizeX(dosname:string):integer;

var
	pasfile		: text;
	size		: integer;
	col		: integer;
	color		: integer;
	length		: integer;

begin
	size:=0;
	assign(pasfile,dosname);
	reset(pasfile);
	readln(pasfile,lineoftext);
	if(lineoftext='FORMAT=LINE')then
		while not eoln(pasfile) do
		begin
			read(pasfile,color);
			read(pasfile,ch);
			read(pasfile,length);
			if not eoln(pasfile) then read(pasfile,ch);
			size:=size + length;
		end;
	close(pasfile);
	getlnsizex:=size;
end;
{--------------------------------------------------------------------------}
function GetLNSizeY(dosname:string):integer;

var
	pasfile		: text;
	size		: integer;

begin
	size:=0;
	assign(pasfile,dosname);
	reset(pasfile);
	readln(pasfile,lineoftext);
	if(lineoftext='FORMAT=LINE')then
		while not eof(pasfile) do
                begin
                        readln(pasfile);
			size:=size + 1;
                end;
	close(pasfile);
	getlnsizey:=size;
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
          write('LN file (input): ');
          readln(lnfile);
	  xsize:=getlnsizex(lnfile);
          writeln('x size: ',xsize);
          ysize:=getlnsizey(lnfile);
          writeln('y size: ',ysize);
          writeln;
          write('BMP file (output): ');
          readln(bmpfile);
          writeln;

          graph_init(device,mode,'c:\tp\bgi');
          ch:=readkey;

          DRAWPICTUREBYLINE(1,1,lnfile);
	  save_bmp(1,1,xsize+1,ysize+1,bmpfile,1);

          ch:=readkey;
          closegraph;
end.

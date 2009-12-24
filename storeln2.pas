program GraphicsByLines;

{Version 2: attempt to add the concept of background in the program}

{Special advantages to storing by line:  (vs pixel)
         1)  Faster drawing
         2)  Shorter Files
Disadvantages:
         1)  Longer program code
             (but it is still much more efficient than actual program coding)}

uses crt, graph;

const
     default        =    0;
     triplex        =    1;
     small          =    2;
     sanseri        =    3;
     gothic         =    4;
     horizontal     =    0;
     vertical       =    1;


type
     stringtype=string[20];
     stringline=string[80];

var
     lineoftext     :    stringline;
     ch             :    char;

var
     device,mode:integer;
     r,x,y,max:integer;
     loop,count:integer;
     color:byte;
     dosname:string[12];
     pasfile:text;
     location:string[80];

     xpos,ypos:integer;
     marker,size:word;
     sizex,sizey:integer;

     xchange,ychange:integer;

     p:^pointer;

{---------------------------------------------------------------------------}
procedure STOREPICTUREBYLINE(beginx,beginy,endx,endy:integer;dosname:stringtype;
                       invis:integer;whiteout:boolean);

{dosname            =    name of the file, including extention
beginx, beginy      =    the coordinates of where the upper left hand corner
                         of the picture
endx, endy          =    lower right hand corner of the picture
invis               =    background color made invisible, set to -1 for none
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
                                   if(invis=color)then
                                        write(pasfile,-1)
                                   else
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
procedure DRAWPICTUREBYLINE(beginx,beginy:integer;dosname:stringtype);

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
                                   if(color>=0)then
                                        begin
                                             setcolor(color);
                                             line(col,row,(col+length),row);
                                        end;
                                   col:=col + length;
                              end;
                         readln(pasfile);
                         row:=row + 1;
                         col:=beginx;
                    end;
          end;
     close(pasfile);

end;
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


begin
     write('filename:  ');
     readln(dosname);
     gfilesloc(device,mode,'c:\tp\bgi');

     DRAWPICTUREBYLINE(100,100,dosname);
     ch:=readkey;

     STOREPICTUREBYLINE(100,100,151,151,dosname,black,true);
     ch:=readkey;

     setfillstyle(xhatchfill,blue);
     floodfill(1,1,white);

     DRAWPICTUREBYLINE(10,10,dosname);

     ch:=readkey;

end.
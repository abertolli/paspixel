{Copyright (C) 2000 - Angelo Bertolli}
{*************************************************************************
PasDraw

Drawing program written with Turbo Pascal 6.0.  Drawing and graphics
manipulation.  Supports LN1 and CD1 types.  LN1 types contain colors and
line lengths.  CD1 types contain graphics code.  Converting from LN1 to
CD1 will make code for lines (inefficient).  Converting from CD1 to LN1
will record colors and line lengths.  LN1 and CD1 are essentially text
files.

** LN1 Format **

The file starts out with FORMAT=LINE.  This line must be read first.
Each subsequent line in the file is another line of pixels.  A color is
read, then the length of number of pixels of that color.  The end of the
file indicates the end of the picture.

** LN1 Example **

Here is the LN1 example for a black square 5x5.

FORMAT=LINE
0 5
0 5
0 5
0 5
0 5

** CD1 Format **

The file starts out with FORMAT=CODE.  Each line is a separate graphics
"command."  This format can draw over other objects and leave them in the
background.  The different "commands" for drawing objects follow below.
Numbers for location are relative to an upper left-hand corner point of
(0,0).  All non-capital letters in code are numbers.

(code <include spaces>=equivalent command)
B x1 y1 x2 y2=bar(x1,y1,x2,y2)
E x y sa ea xr yr=ellipse(x,y,startangle,endangle,xrad,yrad)
FE x y xr yr=fillellipse(x,y,xrad,yrad)
F x y bc=floodfill(x,y,bordercolor)
L x1 y1 x2 y2=line(x1,y1,x2,y2)
P x y c=putpixel(x,y,color)
R x1 y1 x2 y2=rectangle(x1,y1,x2,y2)
S c=setcolor(color)
SF p c=setfillstyle(pattern,color)
SL s p t=setlinestyle(style,pattern,thickness)
ST f d s=settextstyle(font,direction,size)
O x y st=outtextxy(x,y,st)

     (colors)
     black          0         brown          6         lightcyan     11
     blue           1         lightgray      7         lightred      12
     green          2         darkgray       8         lightmagenta  13
     cyan           3         lightblue      9         yellow        14
     red            4         lightgreen    10         white         15
     magenta        5

     (fill patterns)
     EmptyFill           0        Uses background color
     SolidFill           1        Uses draw color
     LineFill            2        --- fill
     LtSlashFill         3        /// fill
     SlashFill           4        /// thick fill
     BkSlashFill         5        \\\ thick fill
     LtBkSlashFill       6        \\\ fill
     HatchFill           7        Light hatch fill
     XHatchFill          8        Heavy cross hatch
     InterleaveFill      9        Interleaving line
     WideDotFill        10        Widely spaced dot
     CloseDotFill       11        Closely spaced dot
     UserFill           12        User-defined fill

     (line styles, use case)
     solidln        0         centerln       2
     dottedln       1         dashedln       3

     line pattern:  0

     (line thickness)
     normwidth      1
     thickwidth     3

     (text font)
     default font   0         sanseri        3
     triplex        1         gothic         4
     small          2

     (text direction)
     horizontal     0
     verticle       1

     text size:  0 or greater

** CD1 Example **

Here is an example of the CD1 file for a red circle positioned at relative
point (10,10) with radius 5.

FORMAT=CODE
E 10 10 0 360 5 5

*************************************************************************}

program PasDraw;

uses crt, graph;

const

     default        =    0;

     horizontal     =    0;
     vertical       =    1;

     enter          =    #13;
     backspace      =    #8;
     ESC            =    #27;

     xmaxsize       =    460;
     ymaxsize       =    460;
     lmargin        =    xmaxsize+5;

type
     stringtype     =    string[40];
     stringline     =    string[100];
     picturetype    =    object
                              filename       :    stringtype;
                              savefile       :    text;
                              modified       :    boolean;
                              tempname       :    stringtype;
                              tempfile       :    text;
                              xsize          :    integer;
                              ysize          :    integer;
                              xcursor        :    integer;
                              ycursor        :    integer;
                              constructor    init;
                              destructor     done;
                              procedure      refresh;
                              procedure      mainmenu;
                              procedure      prompt;
                              procedure      gwrite(var x,y:integer;gtext:string);
                              procedure      gwriteln(var x,y:integer;gtext:string);
                              procedure      gread(var x,y:integer;var gtext:stringtype);
                              procedure      homecursor(var x,y:integer);
                              procedure      centerwrite(x,y:integer;gtext:string);
                              function       nextfile(thefile:stringtype):stringtype;
                              procedure      newpic;
                              procedure      loadpic;
                              procedure      savepic;
                              procedure      drawpic;
                              procedure      addtotemp(lineoftext:stringline);
                              function       exist(dosname:stringtype):boolean;
                              procedure      storepicturebyline(beginx,beginy,endx,endy:integer;
                                                                dosname:stringtype;
                                                                whiteout:boolean);
                              procedure      drawpicturebyline(beginx,beginy:integer;dosname:stringtype);
                              procedure      drawpicturebycode(beginx,beginy:integer;dosname:stringtype);
                              procedure      picsize;
                         end;

var
     loop           :    integer;
     device         :    integer;
     mode           :    integer;
     picture        :    picturetype;

{---------------------------------------------------------------------------}
constructor picturetype.init;

var
     nextname  :    stringtype;

begin
     filename:='';
     modified:=false;
     tempname:='temp.001';
     if not(exist(tempname)) then
          begin
               assign(tempfile,tempname);
               rewrite(tempfile);
               writeln(tempfile,'FORMAT=CODE');
               close(tempfile);
          end
     else
          begin
               nextname:=nextfile(tempname);
               while (exist(nextname)) do
                    begin
                         tempname:=nextname;
                         nextname:=nextfile(tempname);
                    end;
          end;
     xsize:=xmaxsize;
     ysize:=ymaxsize;
end;
{---------------------------------------------------------------------------}
destructor picturetype.done;

begin
     cleardevice;
end;
{--------------------------------------------------------------------------}
function picturetype.exist(dosname:stringtype) : boolean;

{Returns TRUE if the file exists.}

var
     pasfile        :   text;

begin
     {$I-}
     assign(pasfile,dosname);
     reset(pasfile);
     close(pasfile);
     {$I+}
     exist:=(IoResult=0);
end;

{---------------------------------------------------------------------------}
function picturetype.nextfile(thefile:stringtype):stringtype;

var
     newstring :    string[3];
     loop      :    integer;
     newvalue  :    integer;
     errcode   :    integer;

begin
     newstring:='';
     for loop:=(pos('.',thefile)+1) to length(thefile) do
          newstring:=newstring + thefile[loop];
     val(newstring,newvalue,errcode);
     inc(newvalue);
     str(newvalue:3,newstring);
     for loop:=1 to 3 do
          if (newstring[loop]=' ') then
               newstring[loop]:='0';
     if (newvalue>=1000) then
          newstring:='001';
     nextfile:='temp.'+newstring;
end;
{---------------------------------------------------------------------------}
procedure picturetype.refresh;

begin
     {adjust temp file to exclude area outside of size, use next temp file}
     drawpicturebycode(1,1,tempname);
end;
{---------------------------------------------------------------------------}
procedure picturetype.newpic;

begin
     tempname:=nextfile(tempname);
     assign(tempfile,tempname);
     rewrite(tempfile);
     writeln(tempfile,'FORMAT=CODE');
     close(tempfile);
end;
{---------------------------------------------------------------------------}
procedure picturetype.loadpic;

var
     loaded    :    boolean;
     s         :    stringtype;
     pasfile   :    text;
     firstline :    stringline;
     ch        :    char;
     color     :    integer;
     length    :    integer;
     ypos      :    integer;
     xpos      :    integer;

begin
     xsize:=1;
     ysize:=1;
     loaded:=false;
     gwriteln(xcursor,ycursor,'');
     gwriteln(xcursor,ycursor,'Load filename:');
     gread(xcursor,ycursor,s);
     gwriteln(xcursor,ycursor,'');
     if not(exist(s)) then
          gwriteln(xcursor,ycursor,'File does not exist.')
     else
          begin
               assign(pasfile,s);
               reset(pasfile);
               readln(pasfile,firstline);
               close(pasfile);
               if (firstline='FORMAT=CODE') then
                    begin
                         filename:=s;
                         tempname:=nextfile(tempname);
                         assign(tempfile,tempname);
                         rewrite(tempfile);
                         assign(savefile,filename);
                         reset(savefile);
                         readln(savefile,firstline);
                         writeln(tempfile,firstline);
                         while not(eof(savefile)) do
                              begin
                                   while not(eoln(savefile)) do
                                        begin
                                             read(savefile,ch);
                                             write(tempfile,ch);
                                        end;
                                   readln(savefile);
                                   writeln(tempfile);
                              end;
                         close(savefile);
                         close(tempfile);
                         loaded:=true;
                    end
               else
                    if (firstline='FORMAT=LINE') then
                         begin
                              filename:=s;
                              tempname:=nextfile(tempname);
                              assign(tempfile,tempname);
                              rewrite(tempfile);
                              assign(savefile,filename);
                              reset(savefile);
                              readln(savefile,firstline);
                              writeln(tempfile,'FORMAT=CODE');
                              ypos:=0;
                              while not(eof(savefile)) do
                                   begin
                                        xpos:=0;
                                        while not(eoln(savefile)) do
                                             begin
                                                  read(savefile,color);
                                                  read(savefile,ch);
                                                  write(tempfile,'S ');
                                                  write(tempfile,color);
                                                  writeln(tempfile);
                                                  read(savefile,length);
                                                  if not(eoln(savefile)) then
                                                       read(savefile,ch);
                                                  write(tempfile,'L ');
                                                  write(tempfile,xpos);
                                                  write(tempfile,' ');
                                                  write(tempfile,ypos);
                                                  write(tempfile,' ');
                                                  xpos:=xpos+length;
                                                  write(tempfile,xpos);
                                                  write(tempfile,' ');
                                                  write(tempfile,ypos);
                                                  writeln(tempfile);
                                             end;
                                        readln(savefile);
                                        inc(ypos);
                                        if (ypos>ysize) then
                                             ysize:=ypos;
                                        if (xpos>xsize) then
                                             xsize:=xpos;
                                   end;
                              close(savefile);
                              close(tempfile);
                              loaded:=true;
                         end
                    else
                         gwriteln(xcursor,ycursor,'Invalid format.');
          end;
     if (loaded) then
          begin
               gwriteln(xcursor,ycursor,'Loaded.');
          end;
     prompt;

end;
{---------------------------------------------------------------------------}
procedure picturetype.savepic;

var
     s         :    stringtype;
     saved     :    boolean;
     ch        :    char;
     goahead   :    boolean;

begin
     saved:=false;
     repeat
          cleardevice;
          homecursor(xcursor,ycursor);
          gwriteln(xcursor,ycursor,'');
          gwriteln(xcursor,ycursor,'Save');
          gwriteln(xcursor,ycursor,'');
          gwriteln(xcursor,ycursor,'* Filename ['+filename+']: ');
          gread(xcursor,ycursor,s);
          gwriteln(xcursor,ycursor,'');
          gwriteln(xcursor,ycursor,'');
          goahead:=true;
          if (exist(s)) then
               begin
                    gwriteln(xcursor,ycursor,'File exists.');
                    gwriteln(xcursor,ycursor,'Overwrite? (y/n/ESC)');
                    repeat
                         ch:=readkey;
                         ch:=upcase(ch);
                    until (ch in ['Y','N',ESC]);
                    goahead:=(ch='Y');
                    saved:=(ch=ESC);
               end;
          if goahead then
               begin
                    if (s<>'') then
                         filename:=s;
                    gwriteln(xcursor,ycursor,'Choose format:');
                    gwriteln(xcursor,ycursor,'  1) LN1');
                    gwriteln(xcursor,ycursor,'  2) CD1');
                    repeat
                         ch:=readkey;
                    until (ch in ['1','2']);
                    if (ch='1') then
                         begin
                              refresh;
                              storepicturebyline(1,1,xsize,ysize,filename,true);
                              modified:=false;
                         end
                    else
                         begin
                              assign(tempfile,tempname);
                              assign(savefile,filename);
                              reset(tempfile);
                              rewrite(savefile);
                              while not(eof(tempfile)) do
                                   begin
                                        while not(eoln(tempfile)) do
                                             begin
                                                  read(tempfile,ch);
                                                  write(savefile,ch);
                                             end;
                                        readln(tempfile);
                                        writeln(savefile);
                                   end;
                              close(tempfile);
                              close(savefile);
                              modified:=false;
                         end;
                    saved:=true;
               end;
     until saved;

end;
{---------------------------------------------------------------------------}
procedure picturetype.picsize;

var
     s         :    stringtype;
     i         :    integer;
     errcode   :    integer;
     error     :    boolean;

begin
     gwriteln(xcursor,ycursor,'');
     gwriteln(xcursor,ycursor,'Current Size');
     gwrite(xcursor,ycursor,'x - ');
     str(xsize,s);
     gwriteln(xcursor,ycursor,s);
     gwrite(xcursor,ycursor,'y - ');
     str(ysize,s);
     gwriteln(xcursor,ycursor,s);
     gwriteln(xcursor,ycursor,'');
     gwriteln(xcursor,ycursor,'Input New Size');
     error:=false;
     gwrite(xcursor,ycursor,'x - ');
     gread(xcursor,ycursor,s);
     gwriteln(xcursor,ycursor,'');
     val(s,i,errcode);
     error:=(errcode<>0) or (i<=1) or (i>xmaxsize);
     if not(error) then
          xsize:=i
     else
          gwriteln(xcursor,ycursor,'Error! (unchanged)');
     gwrite(xcursor,ycursor,'y - ');
     gread(xcursor,ycursor,s);
     gwriteln(xcursor,ycursor,'');
     val(s,i,errcode);
     error:=(errcode<>0) or (i<=1) or (i>ymaxsize);
     if not(error) then
          ysize:=i
     else
          begin
               gwriteln(xcursor,ycursor,'Error! (unchanged)');
               prompt;
          end;
end;
{---------------------------------------------------------------------------}
procedure picturetype.drawpic;

var
     quit      :    boolean;
     ch        :    char;
     loop      :    integer;
     lines     :    word;
     newname   :    stringtype;
     newfile   :    text;
     lineoftext:    stringline;
     strarg    :    array[1..6] of stringtype;
     tempstr   :    stringtype;

begin
     quit:=false;
     repeat
          cleardevice;
          refresh;
          setcolor(white);
          settextstyle(default,horizontal,1);
          setlinestyle(3,0,1);
          rectangle(0,0,getmaxx,getmaxy);
          line(xsize+1,0,xsize+1,ysize+1);
          line(0,ysize+1,xsize+1,ysize+1);
          setlinestyle(0,0,1);
          homecursor(xcursor,ycursor);
          centerwrite(xcursor,ycursor,'Draw Menu');
          gwriteln(xcursor,ycursor,'');
          gwriteln(xcursor,ycursor,'');
          gwriteln(xcursor,ycursor,'(B)ar');
          gwriteln(xcursor,ycursor,'(E)llipse');
          gwriteln(xcursor,ycursor,'(F)illed Ellipse');
          gwriteln(xcursor,ycursor,'(L)ine');
          gwriteln(xcursor,ycursor,'(P)ixel');
          gwriteln(xcursor,ycursor,'(R)ectangle');
          gwriteln(xcursor,ycursor,'(S)et Color');
          gwriteln(xcursor,ycursor,'(U)ndo');
          gwriteln(xcursor,ycursor,'(W)rite text');
          gwriteln(xcursor,ycursor,'(*)Flood Fill');
          gwriteln(xcursor,ycursor,'');
          gwriteln(xcursor,ycursor,'-Set Styles-');
          gwriteln(xcursor,ycursor,' (1) Set Fill Style');
          gwriteln(xcursor,ycursor,' (2) Set Line Style');
          gwriteln(xcursor,ycursor,' (3) Set Text Style');
          gwriteln(xcursor,ycursor,'');
          gwriteln(xcursor,ycursor,'<ESC> Main Menu');
          repeat
               ch:=readkey;
               ch:=upcase(ch);
          until (ch in ['B','E','F','L','P','R','S','U','1','2','3','W','*',ESC]);
          setcolor(white);
          settextstyle(default,horizontal,1);
          gwriteln(xcursor,ycursor,'');
          for loop:=1 to 6 do
               strarg[loop]:='';
          lineoftext:='';
          case ch of
               'B': begin
                         gwriteln(xcursor,ycursor,'Bar');
                         gwrite(xcursor,ycursor,'X1: ');
                         gread(xcursor,ycursor,strarg[1]);
                         gwriteln(xcursor,ycursor,'');
                         gwrite(xcursor,ycursor,'Y1: ');
                         gread(xcursor,ycursor,strarg[2]);
                         gwriteln(xcursor,ycursor,'');
                         gwrite(xcursor,ycursor,'X2: ');
                         gread(xcursor,ycursor,strarg[3]);
                         gwriteln(xcursor,ycursor,'');
                         gwrite(xcursor,ycursor,'Y2: ');
                         gread(xcursor,ycursor,strarg[4]);
                         lineoftext:='B';
                    end;
               'E': begin
                         gwriteln(xcursor,ycursor,'Ellipse');
                         gwrite(xcursor,ycursor,'X: ');
                         gread(xcursor,ycursor,strarg[1]);
                         gwriteln(xcursor,ycursor,'');
                         gwrite(xcursor,ycursor,'Y: ');
                         gread(xcursor,ycursor,strarg[2]);
                         gwriteln(xcursor,ycursor,'');
                         gwrite(xcursor,ycursor,'StartAngle: ');
                         gread(xcursor,ycursor,strarg[3]);
                         gwriteln(xcursor,ycursor,'');
                         gwrite(xcursor,ycursor,'EndAngle: ');
                         gread(xcursor,ycursor,strarg[4]);
                         gwriteln(xcursor,ycursor,'');
                         gwrite(xcursor,ycursor,'XRad: ');
                         gread(xcursor,ycursor,strarg[5]);
                         gwriteln(xcursor,ycursor,'');
                         gwrite(xcursor,ycursor,'YRad: ');
                         gread(xcursor,ycursor,strarg[6]);
                         lineoftext:='E';
                    end;
               'F': begin
                         gwriteln(xcursor,ycursor,'Filled Ellipse');
                         gwrite(xcursor,ycursor,'X: ');
                         gread(xcursor,ycursor,strarg[1]);
                         gwriteln(xcursor,ycursor,'');
                         gwrite(xcursor,ycursor,'Y: ');
                         gread(xcursor,ycursor,strarg[2]);
                         gwriteln(xcursor,ycursor,'');
                         gwrite(xcursor,ycursor,'XRad: ');
                         gread(xcursor,ycursor,strarg[3]);
                         gwriteln(xcursor,ycursor,'');
                         gwrite(xcursor,ycursor,'YRad: ');
                         gread(xcursor,ycursor,strarg[4]);
                         lineoftext:='FE';
                    end;
               'L': begin
                         gwriteln(xcursor,ycursor,'Line');
                         gwrite(xcursor,ycursor,'X1: ');
                         gread(xcursor,ycursor,strarg[1]);
                         gwriteln(xcursor,ycursor,'');
                         gwrite(xcursor,ycursor,'Y1: ');
                         gread(xcursor,ycursor,strarg[2]);
                         gwriteln(xcursor,ycursor,'');
                         gwrite(xcursor,ycursor,'X2: ');
                         gread(xcursor,ycursor,strarg[3]);
                         gwriteln(xcursor,ycursor,'');
                         gwrite(xcursor,ycursor,'Y2: ');
                         gread(xcursor,ycursor,strarg[4]);
                         lineoftext:='L';
                    end;
               'P': begin
                         gwriteln(xcursor,ycursor,'Put Pixel');
                         gwrite(xcursor,ycursor,'X: ');
                         gread(xcursor,ycursor,strarg[1]);
                         gwriteln(xcursor,ycursor,'');
                         gwrite(xcursor,ycursor,'Y: ');
                         gread(xcursor,ycursor,strarg[2]);
                         gwriteln(xcursor,ycursor,'');
                         for loop:=1 to 8 do
                              line(lmargin+loop,ycursor,lmargin+loop,ycursor+8);
                         settextstyle(smallfont,horizontal,2);
                         for loop:=0 to 15 do
                              begin
                                   str(loop,tempstr);
                                   setcolor(loop);
                                   gwrite(xcursor,ycursor,' ' + tempstr);
                              end;
                         gwriteln(xcursor,ycursor,'');
                         setcolor(white);
                         settextstyle(default,horizontal,1);
                         gwrite(xcursor,ycursor,'color: ');
                         gread(xcursor,ycursor,strarg[3]);
                         lineoftext:='P';
                    end;
               'R': begin
                         gwriteln(xcursor,ycursor,'Rectangle');
                         gwrite(xcursor,ycursor,'X1: ');
                         gread(xcursor,ycursor,strarg[1]);
                         gwriteln(xcursor,ycursor,'');
                         gwrite(xcursor,ycursor,'Y1: ');
                         gread(xcursor,ycursor,strarg[2]);
                         gwriteln(xcursor,ycursor,'');
                         gwrite(xcursor,ycursor,'X2: ');
                         gread(xcursor,ycursor,strarg[3]);
                         gwriteln(xcursor,ycursor,'');
                         gwrite(xcursor,ycursor,'Y2: ');
                         gread(xcursor,ycursor,strarg[4]);
                         lineoftext:='R';
                    end;
               'S': begin
                         for loop:=1 to 8 do
                              line(lmargin+loop,ycursor,lmargin+loop,ycursor+8);
                         settextstyle(smallfont,horizontal,2);
                         for loop:=0 to 15 do
                              begin
                                   str(loop,tempstr);
                                   setcolor(loop);
                                   gwrite(xcursor,ycursor,' ' + tempstr);
                              end;
                         gwriteln(xcursor,ycursor,'');
                         setcolor(white);
                         settextstyle(default,horizontal,1);
                         gwrite(xcursor,ycursor,'Set Color: ');
                         gread(xcursor,ycursor,strarg[1]);
                         lineoftext:='S';
                    end;
               'U': begin
                         newname:=nextfile(tempname);
                         assign(tempfile,tempname);
                         reset(tempfile);
                         lines:=0;
                         while not(eof(tempfile)) do
                              begin
                                   inc(lines);
                                   readln(tempfile);
                              end;
                         close(tempfile);
                         dec(lines);
                         if (lines<1) then
                              lines:=1;
                         assign(tempfile,tempname);
                         assign(newfile,newname);
                         reset(tempfile);
                         rewrite(newfile);
                         for loop:=1 to lines do
                              begin
                                   while not(eoln(tempfile)) do
                                        begin
                                             read(tempfile,ch);
                                             write(newfile,ch);
                                        end;
                                   readln(tempfile);
                                   writeln(newfile);
                              end;
                         close(tempfile);
                         close(newfile);
                         tempname:=newname;
                    end;
               '1': begin
                         gwriteln(xcursor,ycursor,'Set Fill Style');
                         gwriteln(xcursor,ycursor,'(0-12)');
                         gwrite(xcursor,ycursor,'Pattern: ');
                         gread(xcursor,ycursor,strarg[1]);
                         gwriteln(xcursor,ycursor,'');
                         for loop:=1 to 8 do
                              line(lmargin+loop,ycursor,lmargin+loop,ycursor+8);
                         settextstyle(smallfont,horizontal,2);
                         for loop:=0 to 15 do
                              begin
                                   str(loop,tempstr);
                                   setcolor(loop);
                                   gwrite(xcursor,ycursor,' ' + tempstr);
                              end;
                         gwriteln(xcursor,ycursor,'');
                         setcolor(white);
                         settextstyle(default,horizontal,1);
                         gwrite(xcursor,ycursor,'Color: ');
                         gread(xcursor,ycursor,strarg[2]);
                         lineoftext:='SF';
                    end;
               '2': begin
                         gwriteln(xcursor,ycursor,'Set Line Style');
                         gwriteln(xcursor,ycursor,'(0-3)');
                         gwrite(xcursor,ycursor,'Style: ');
                         gread(xcursor,ycursor,strarg[1]);
                         gwriteln(xcursor,ycursor,'');
                         strarg[2]:='0';
                         gwriteln(xcursor,ycursor,'(1 or 3)');
                         gwrite(xcursor,ycursor,'Thickness: ');
                         gread(xcursor,ycursor,strarg[3]);
                         lineoftext:='SL';
                    end;
               '3': begin
                         gwriteln(xcursor,ycursor,'Set Text Style');
                         gwriteln(xcursor,ycursor,'(0-4)');
                         gwrite(xcursor,ycursor,'Font: ');
                         gread(xcursor,ycursor,strarg[1]);
                         gwriteln(xcursor,ycursor,'');
                         gwriteln(xcursor,ycursor,'horiz-0 vert-1');
                         gwrite(xcursor,ycursor,'Direction: ');
                         gread(xcursor,ycursor,strarg[2]);
                         gwriteln(xcursor,ycursor,'');
                         gwriteln(xcursor,ycursor,'(0+)');
                         gwrite(xcursor,ycursor,'Size: ');
                         gread(xcursor,ycursor,strarg[3]);
                         lineoftext:='ST';
                    end;
               'W': begin
                         gwriteln(xcursor,ycursor,'Write Text');
                         gwrite(xcursor,ycursor,'X: ');
                         gread(xcursor,ycursor,strarg[1]);
                         gwriteln(xcursor,ycursor,'');
                         gwrite(xcursor,ycursor,'Y: ');
                         gread(xcursor,ycursor,strarg[2]);
                         gwriteln(xcursor,ycursor,'');
                         gwriteln(xcursor,ycursor,'TEXT');
                         gread(xcursor,ycursor,strarg[3]);
                         lineoftext:='O';
                    end;
               '*': begin
                         gwriteln(xcursor,ycursor,'Flood Fill');
                         gwrite(xcursor,ycursor,'X: ');
                         gread(xcursor,ycursor,strarg[1]);
                         gwriteln(xcursor,ycursor,'');
                         gwrite(xcursor,ycursor,'Y: ');
                         gread(xcursor,ycursor,strarg[2]);
                         gwriteln(xcursor,ycursor,'');
                         for loop:=1 to 8 do
                              line(lmargin+loop,ycursor,lmargin+loop,ycursor+8);
                         settextstyle(smallfont,horizontal,2);
                         for loop:=0 to 15 do
                              begin
                                   str(loop,tempstr);
                                   setcolor(loop);
                                   gwrite(xcursor,ycursor,' ' + tempstr);
                              end;
                         gwriteln(xcursor,ycursor,'');
                         setcolor(white);
                         settextstyle(default,horizontal,1);
                         gwrite(xcursor,ycursor,'border: ');
                         gread(xcursor,ycursor,strarg[3]);
                         gwriteln(xcursor,ycursor,'');
                         lineoftext:='F';
                    end;
          end;{case}
          for loop:=1 to 6 do
               if (strarg[loop]<>'') then
                    begin
                         lineoftext:=lineoftext + ' ';
                         lineoftext:=lineoftext + strarg[loop];
                    end;
          if (lineoftext<>'') then
               addtotemp(lineoftext);
          quit:=(ch=ESC);
     until quit;
end;
{---------------------------------------------------------------------------}
procedure picturetype.addtotemp(lineoftext:stringline);

begin
     assign(tempfile,tempname);
     append(tempfile);
     writeln(tempfile,lineoftext);
     close(tempfile);
end;
{---------------------------------------------------------------------------}
procedure picturetype.mainmenu;

var
     quit      :    boolean;
     ch        :    char;
     ans       :    char;

begin
     quit:=false;
     repeat
          cleardevice;
          refresh;
          setcolor(white);
          settextstyle(default,horizontal,1);
          setlinestyle(3,0,1);
          rectangle(0,0,getmaxx,getmaxy);
          line(xsize+1,0,xsize+1,ysize+1);
          line(0,ysize+1,xsize+1,ysize+1);
          setlinestyle(0,0,1);
          homecursor(xcursor,ycursor);
          centerwrite(xcursor,ycursor,'Main Menu');
          gwriteln(xcursor,ycursor,'');
          gwriteln(xcursor,ycursor,'');
          gwriteln(xcursor,ycursor,'(N)ew picture');
          gwriteln(xcursor,ycursor,'(L)oad picture');
          gwriteln(xcursor,ycursor,'(S)ave picture');
          gwriteln(xcursor,ycursor,'(A)djust size');
          gwriteln(xcursor,ycursor,'(D)raw!');
          gwriteln(xcursor,ycursor,'(R)efresh');
          gwriteln(xcursor,ycursor,'<ESC> Quit');
          gwriteln(xcursor,ycursor,'');
          gwrite(xcursor,ycursor,'Temp file: ');
          gwriteln(xcursor,ycursor,tempname);
          repeat
               ch:=readkey;
               ch:=upcase(ch);
          until (ch in ['N','L','S','D','A','R',ESC]);
          setcolor(white);
          settextstyle(default,horizontal,1);
          if (ch in ['L','N']) and (modified) then
               begin
                    gwriteln(xcursor,ycursor,'');
                    gwriteln(xcursor,ycursor,'Picture not saved.');
                    gwriteln(xcursor,ycursor,'Save? (y/n)');
                    repeat
                         ans:=readkey;
                         ans:=upcase(ans);
                    until (ans in ['Y','N']);
                    if (ans='Y') then
                         savepic
                    else
                         modified:=false;
               end;
          case ch of
               'N':newpic;
               'L':loadpic;
               'S':savepic;
               'D':drawpic;
               'A':picsize;
          end;{case}
          if (ch in ['D','A']) then
               modified:=true;
          quit:=(ch=ESC);
          if (quit) and (modified) then
               begin
                    gwriteln(xcursor,ycursor,'');
                    gwriteln(xcursor,ycursor,'Picture not saved.');
                    gwriteln(xcursor,ycursor,'Save? (y/n)');
                    repeat
                         ch:=readkey;
                         ch:=upcase(ch);
                    until (ch in ['Y','N']);
                    if (ch='Y') then
                         savepic;
               end;
     until quit;
end;
{---------------------------------------------------------------------------}
procedure picturetype.prompt;

var
     thecolor       :    integer;
     ch             :    char;

begin
     ycursor:=getmaxy -(textheight('M')+2) -1;
     centerwrite(xcursor,ycursor,'<press a key> -cont.-');
     ch:=readkey;
end;
{---------------------------------------------------------------------------}
procedure picturetype.GWRITE(var x,y:integer;gtext:string);

begin
     outtextxy(x,y,(gtext));
     x:=x + textwidth(gtext);
end;
{---------------------------------------------------------------------------}
procedure picturetype.GWRITELN(var x,y:integer;gtext:string);

begin
     outtextxy(x,y,(gtext));
     y:=y + textheight('M') + 2;
     x:=lmargin;
end;
{---------------------------------------------------------------------------}
procedure picturetype.GREAD(var x,y:integer;var gtext:stringtype);

var
     lastletter     :    integer;
     theletter      :    char;
     forecolor      :    word;
     ch             :    char;

begin
     forecolor:=getcolor;
     gtext:='';
     repeat
          ch:=readkey;
          if(ch<>enter)then
               begin
                    if(ch<>backspace)then
                         begin
                              gtext:=gtext + ch;
                              gwrite(x,y,ch);
                         end
                    else
                         if(gtext<>'')then
                              begin
                                   lastletter:=length(gtext);
                                   theletter:=gtext[lastletter];
                                   delete(gtext,lastletter,1);
                                   x:=x - textwidth(theletter);
                                   setcolor(getbkcolor);
                                   gwrite(x,y,theletter);
                                   x:=x - textwidth(theletter);
                                   setcolor(forecolor);
                              end;
               end;
     until(ch=enter);
end;
{---------------------------------------------------------------------------}
procedure picturetype.HOMECURSOR(var x,y:integer);

begin
     x:=lmargin;
     y:=10;
end;
{---------------------------------------------------------------------------}
procedure picturetype.CENTERWRITE(x,y:integer;gtext:string);

var
     width     :    integer;

begin
     width:=textwidth(gtext);
     x:=(lmargin +((getmaxx-lmargin) DIV 2)) -(width DIV 2);
     if (x<lmargin) then
          x:=lmargin;
     outtextxy(x,y,(gtext));
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
{---------------------------------------------------------------------------}
procedure picturetype.STOREPICTUREBYLINE(beginx,beginy,endx,endy:integer;dosname:stringtype;
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
procedure picturetype.DRAWPICTUREBYLINE(beginx,beginy:integer;dosname:stringtype);

{dosname            =    name of the file, including extention
beginx, beginy      =    the coordinates of where the upper left hand corner
                         of where the picture will be.}

type
     stringline     =    string[100];

var
     pasfile        :    text;
     row            :    integer;
     col            :    integer;
     color          :    integer;
     length         :    integer;
     lineoftext     :    stringline;
     ch             :    char;

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
{---------------------------------------------------------------------------}
procedure picturetype.DRAWPICTUREBYCODE(beginx,beginy:integer;dosname:stringtype);

{dosname            =    name of the file, including extention
beginx, beginy      =    the coordinates of where the upper left hand corner
                         of where the picture will be.}

type
     stringline     =    string[100];

var
     pasfile        :    text;
     color          :    integer;
     cd             :    char;
     lineoftext     :    stringline;
     ch             :    char;

{..........................................................................}
procedure barcode(beginx,beginy:integer);

var
     bx1            :    integer;
     bx2            :    integer;
     by1            :    integer;
     by2            :    integer;

begin
     read(pasfile,cd);
     read(pasfile,bx1);
     read(pasfile,cd);
     read(pasfile,by1);
     read(pasfile,cd);
     read(pasfile,bx2);
     read(pasfile,cd);
     read(pasfile,by2);
     bx1:=bx1 + beginx;
     bx2:=bx2 + beginx;
     by1:=by1 + beginy;
     by2:=by2 + beginy;
     bar(bx1,by1,bx2,by2);
end;
{..........................................................................}
procedure ellipsecode(beginx,beginy:integer);

var
     ex             :    integer;
     ey             :    integer;
     esa            :    integer;
     eea            :    integer;
     exr            :    integer;
     eyr            :    integer;

begin
     read(pasfile,cd);
     read(pasfile,ex);
     read(pasfile,cd);
     read(pasfile,ey);
     read(pasfile,cd);
     read(pasfile,esa);
     read(pasfile,cd);
     read(pasfile,eea);
     read(pasfile,cd);
     read(pasfile,exr);
     read(pasfile,cd);
     read(pasfile,eyr);
     ex:=ex + beginx;
     ey:=ey + beginy;
     ellipse(ex,ey,esa,eea,exr,eyr);
end;
{..........................................................................}
procedure fillellipsecode(beginx,beginy:integer);

var
     fex            :    integer;
     fey            :    integer;
     fexr           :    integer;
     feyr           :    integer;

begin
     read(pasfile,cd);
     read(pasfile,fex);
     read(pasfile,cd);
     read(pasfile,fey);
     read(pasfile,cd);
     read(pasfile,fexr);
     read(pasfile,cd);
     read(pasfile,feyr);
     fex:=fex + beginx;
     fey:=fey + beginy;
     fillellipse(fex,fey,fexr,feyr);
end;
{..........................................................................}
procedure floodfillcode(beginx,beginy:integer);

var
     fx             :    integer;
     fy             :    integer;
     fbc            :    integer;

begin
     read(pasfile,fx);
     read(pasfile,cd);
     read(pasfile,fy);
     read(pasfile,cd);
     read(pasfile,fbc);
     fx:=fx + beginx;
     fy:=fy + beginy;
     floodfill(fx,fy,fbc);
end;
{..........................................................................}
procedure linecode(beginx,beginy:integer);

var
     lx1            :    integer;
     ly1            :    integer;
     lx2            :    integer;
     ly2            :    integer;

begin
     read(pasfile,cd);
     read(pasfile,lx1);
     read(pasfile,cd);
     read(pasfile,ly1);
     read(pasfile,cd);
     read(pasfile,lx2);
     read(pasfile,cd);
     read(pasfile,ly2);
     lx1:=lx1 + beginx;
     lx2:=lx2 + beginx;
     ly1:=ly1 + beginy;
     ly2:=ly2 + beginy;
     line(lx1,ly1,lx2,ly2);
end;
{..........................................................................}
procedure putpixelcode(beginx,beginy:integer);

var
     px             :    integer;
     py             :    integer;

begin
     read(pasfile,cd);
     read(pasfile,px);
     read(pasfile,cd);
     read(pasfile,py);
     read(pasfile,cd);
     read(pasfile,color);
     px:=px + beginx;
     py:=py + beginy;
     putpixel(px,py,color);
end;
{..........................................................................}
procedure rectanglecode(beginx,beginy:integer);

var
     rx1            :    integer;
     ry1            :    integer;
     rx2            :    integer;
     ry2            :    integer;

begin
     read(pasfile,cd);
     read(pasfile,rx1);
     read(pasfile,cd);
     read(pasfile,ry1);
     read(pasfile,cd);
     read(pasfile,rx2);
     read(pasfile,cd);
     read(pasfile,ry2);
     rx1:=rx1 + beginx;
     rx2:=rx2 + beginx;
     ry1:=ry1 + beginy;
     ry2:=ry2 + beginy;
     rectangle(rx1,ry1,rx2,ry2)
end;
{..........................................................................}
procedure setcolorcode;

begin
     read(pasfile,color);
     setcolor(color);
end;
{..........................................................................}
procedure setfillstylecode;

var
     sfp            :    byte;

begin
     read(pasfile,cd);
     read(pasfile,sfp);
     read(pasfile,cd);
     read(pasfile,color);
     setfillstyle(sfp,color);
end;
{..........................................................................}
procedure setlinestylecode;

var
     sls            :    byte;
     slp            :    byte;
     slt            :    byte;

begin
     read(pasfile,cd);
     read(pasfile,sls);
     read(pasfile,cd);
     read(pasfile,slp);
     read(pasfile,cd);
     read(pasfile,slt);
     setlinestyle(sls,slp,slt);
end;
{..........................................................................}
procedure settextstylecode;

var
     stf            :    integer;
     std            :    integer;
     sts            :    integer;

begin
     read(pasfile,cd);
     read(pasfile,stf);
     read(pasfile,cd);
     read(pasfile,std);
     read(pasfile,cd);
     read(pasfile,sts);
     settextstyle(stf,std,sts);
end;
{..........................................................................}
procedure outtextcode(beginx,beginy:integer);

var
     ox             :    integer;
     oy             :    integer;
     ost            :    string;

begin
     read(pasfile,cd);
     read(pasfile,ox);
     read(pasfile,cd);
     read(pasfile,oy);
     read(pasfile,cd);
     ost:='';
     while not eoln(pasfile) do
          begin
               read(pasfile,cd);
               ost:=ost + cd;
          end;
     ox:=ox + beginx;
     oy:=oy + beginy;
     outtextxy(ox,oy,(ost));
end;
{..........................................................................}

begin

     assign(pasfile,dosname);
     reset(pasfile);
     readln(pasfile,lineoftext);
     if(lineoftext='FORMAT=CODE')then
          begin
               while not eof(pasfile) do
                    begin
                         read(pasfile,cd);
                         case cd of
                              'B':barcode(beginx,beginy);
                              'E':ellipsecode(beginx,beginy);
                              'F':begin
                                       read(pasfile,cd);
                                       case cd of
                                            ' ':floodfillcode(beginx,beginy);
                                            'E':fillellipsecode(beginx,beginy);
                                       end;
                                  end;
                              'L':linecode(beginx,beginy);
                              'P':putpixelcode(beginx,beginy);
                              'R':rectanglecode(beginx,beginy);
                              'S':begin
                                       read(pasfile,cd);
                                       case cd of
                                            ' ':setcolorcode;
                                            'F':setfillstylecode;
                                            'L':setlinestylecode;
                                            'T':settextstylecode;
                                       end;
                                  end;
                              'O':outtextcode(beginx,beginy);
                         end;
                         readln(pasfile);
                    end;
          end;
     close(pasfile);

end;
{---------------------------------------------------------------------------}

begin
     gfilesloc(device,mode,'c:\tp\bgi');
     cleardevice;
     picture.init;
     picture.mainmenu;
     picture.done;
     closegraph;
end.

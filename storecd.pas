program GraphicsByCode;

{Special advantages to storing by code:  (vs pixel)
         1)  Excellent Speed
         2)  Very Small Storage file
         3)  Ability to "draw over" other pictures
Disadvantages:
         1)  Much longer program code
             (yet just 3 or 4 pictures makes this better than actual coding)}

uses crt, graph;

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
     marker,size:byte;
     sizex,sizey:integer;

{********************************* CODES ***********************************}
{            COMMAND                                     CODE
                                         (all non-capital letters are numbers)

        bar(x1,y1,x2,y2)                             B x1 y1 x2 y2

ellipse(x,y,startangle,endangle,xrad,yrad)         E x y sa ea xr yr

     fillellipse(x,y,xrad,yrad)                      FE x y xr yr

     floodfill(x,y,bordercolor)                        F x y bc

        line(x1,y1,x2,y2)                            L x1 y1 x2 y2

       putpixel(x,y,color)                              P x y c

      rectangle(x1,y1,x2,y2)                         R x1 y1 x2 y2

         setcolor(color)                                  S c

    setfillstyle(pattern,color)                          SF p c

setlinestyle(style,pattern,thickness)                   SL s p t

  settextstyle(font,direction,size)                     ST f d s

        outtextxy(x,y,st)                               O x y st

NUMBERS
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
}
{***************************************************************************}
{---------------------------------------------------------------------------}
procedure DRAWPICTUREBYCODE(beginx,beginy:integer;dosname:stringtype);

{dosname            =    name of the file, including extention
beginx, beginy      =    the coordinates of where the upper left hand corner
                         of where the picture will be.}

var
     pasfile        :    text;
     color          :    integer;
     cd             :    char;

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

begin

     write('filename:  ');
     readln(dosname);
     gfilesloc(device,mode,'c:\tp\bgi');

     setcolor(magenta);
     DRAWPICTUREBYCODE(0,0,dosname);
     ch:=readkey;

end.

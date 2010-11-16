program ViewPicture;

{View graphics file by lines or code.}

{$ifdef Win32}
{$apptype GUI}
{$endif}

uses windows, wincrt, graph;

const
     lmargin        =    10;
     default        =    0;
     triplex        =    1;
     small          =    2;
     sanseri        =    3;
     gothic         =    4;
     horizontal     =    0;
     vertical       =    1;
     enter          =    #13;
     backspace      =    #8;

type
     stringtype     =    string[20];
     stringline     =    string[100];
     goodchars      =    set of char;

var
     ch             :    char;
     x,y            :    integer;
     loop           :    integer;
     lineoftext     :    stringline;
     device         :    integer;
     mode           :    integer;
     thefile        :    stringtype;

{--------------------------------------------------------------------------}
function exists(dosname:string) : boolean;

{Returns TRUE if the file exists.}

var
     pasfile        :   text;

begin
     {$I-}
     assign(pasfile,dosname);
     reset(pasfile);
     close(pasfile);
     {$I+}
     exists:=(IoResult=0);
end;
{---------------------------------------------------------------------------}
procedure GPROMPT;

var
     thecolor       :    integer;

begin
     x:=getmaxx - (textwidth('press a key to continue')+5);
     y:=getmaxy - (textheight('M')+5);
     thecolor:=getcolor;
     setcolor(white);
     outtextxy(x,y,'press a key to continue');
     ch:=readkey;
     setcolor(getbkcolor);
     outtextxy(x,y,'press a key to continue');
     setcolor(thecolor);
end;
{---------------------------------------------------------------------------}
procedure GFILESLOC(var gdriver,gmode:integer;gpath:string);

var
     error          :    integer;

begin
	repeat
		gdriver:=detect;
		{$ifdef Win32}
		gdriver:=D4bit;
		gmode:=m800x600;
		ShowWindow(GetActiveWindow,0);
		{$endif}
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
procedure STOREPICTUREBYLINE(beginx,beginy,endx,endy:integer;dosname:stringtype;
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
procedure GWRITE(var x,y:integer;gtext:string);

begin
     outtextxy(x,y,(gtext));
     x:=x + textwidth(gtext);
end;
{---------------------------------------------------------------------------}
procedure GWRITELN(var x,y:integer;gtext:string);

begin
     outtextxy(x,y,(gtext));
     y:=y + textheight('M') + 2;
     x:=lmargin;
end;
{---------------------------------------------------------------------------}
procedure GREAD(var x,y:integer;var gtext:stringtype);

var
     lastletter     :    integer;
     theletter      :    char;
     forecolor      :    word;

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
procedure HOMECURSOR(var x,y:integer);

begin
     x:=10;
     y:=10;
end;
{---------------------------------------------------------------------------}
procedure view(dosname:stringtype);

var
     pasfile        :    text;
     firstline      :    stringtype;

begin

	if (exists(dosname)) then
		begin
		cleardevice;
		assign(pasfile,dosname);
		reset(pasfile);
		readln(pasfile,firstline);
		close(pasfile);
		if (firstline='FORMAT=CODE') then
			drawpicturebycode(1,1,dosname)
		else
			if (firstline='FORMAT=LINE') then
				drawpicturebyline(1,1,dosname)
			else
				gwriteln(x,y,'Unknown format');
		end
	else
		gwriteln(x,y,'No such file.');
	gprompt;

end;
{---------------------------------------------------------------------------}


begin
	gfilesloc(device,mode,'c:\tp\bgi');
	repeat
		cleardevice;
		homecursor(x,y);
		settextstyle(default,horizontal,2);
		gwrite(x,y,'Enter file name:  ');
		gread(x,y,thefile);
		gwriteln(x,y,'');
		view(thefile);
	until (False);
	closegraph;
end.
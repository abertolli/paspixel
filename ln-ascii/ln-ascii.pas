program ConvertLNtoASCII;

uses crt;

var
     LNname:string[20];
     ASCIIname:string[20];
     ans:char;

{--------------------------------------------------------------------------}
procedure LNtoASCII(LNname,ASCIIname:string);

type
     CharTable      =    record
                              color     :    set of byte;
                              ch        :    char;
                         end;

var
     LNfile         :    text;
     ASCIIfile      :    text;
     color          :    integer;
     length         :    integer;
     charset        :    array[1..7] of CharTable;
     loop           :    integer;
     ch             :    char;
     lineoftext     :    string[80];

begin

     {set up the charset}
     charset[1].ch:='*';
     charset[1].color:=[black];
     charset[2].ch:='#';
     charset[2].color:=[darkgray,blue,brown];
     charset[3].ch:='X';
     charset[3].color:=[green,magenta,red];
     charset[4].ch:='@';
     charset[4].color:=[cyan,lightred];
     charset[5].ch:='^';
     charset[5].color:=[lightblue,lightgreen,lightmagenta];
     charset[6].ch:='`';
     charset[6].color:=[yellow,lightcyan,lightgray];
     charset[7].ch:=' ';
     charset[7].color:=[white];

     {start converting}
     assign(LNfile,LNname);
     assign(ASCIIfile,ASCIIname);
     reset(LNfile);
     rewrite(ASCIIfile);
     readln(LNfile,lineoftext);
     while not eof(LNfile) do
          begin
               while not eoln(LNfile) do
                    begin
                         read(LNfile,color);
                         read(LNfile,ch);
                         read(LNfile,length);
                         if not eoln(LNfile) then
                              read(LNfile,ch);
                         for loop:=1 to 7 do
                              if (color in charset[loop].color) then
                                   ch:=charset[loop].ch;
                         for loop:=1 to length do
                              write(ASCIIfile,ch);
                    end;
               readln(LNfile);
               writeln(ASCIIfile);
          end;
     close(LNfile);
     close(ASCIIfile);

end;
{--------------------------------------------------------------------------}
procedure MakeHTML(ASCIIname:string);

var
     HTMLname       :    string;
     HTMLfile       :    text;
     ASCIIfile      :    text;
     loop           :    integer;
     ch             :    char;
     tempstring     :    string;

begin

     loop:=0;
     tempstring:='';
     repeat
          inc(loop);
          tempstring:=tempstring+ASCIIname[loop];
     until ((loop=length(ASCIIname))or(ASCIIname[loop]='.'));

     if (tempstring[loop]<>'.') then
          tempstring:=tempstring+'.';

     HTMLname:=tempstring+'html';

     assign(HTMLfile,HTMLname);
     rewrite(HTMLfile);
     writeln(HTMLfile,'<html>');
     writeln(HTMLfile,'<font face="Courier New,Courier" size=1>');
     writeln(HTMLfile,'<pre>');

     assign(ASCIIfile,ASCIIname);
     reset(ASCIIfile);

     while not eof(ASCIIfile) do
          begin
               while not eoln(ASCIIfile) do
                    begin
                         read(ASCIIfile,ch);
                         write(HTMLfile,ch);
                    end;
               readln(ASCIIfile);
               writeln(HTMLfile);
          end;

     close(ASCIIfile);

     writeln(HTMLfile,'</pre>');
     writeln(HTMLfile,'</font>');
     writeln(HTMLfile,'</html>');
     close(HTMLfile);

end;
{--------------------------------------------------------------------------}


begin

     write('LN filename:  ');
     readln(LNname);
     write('ASCII filename:  ');
     readln(ASCIIname);

     LNtoASCII(LNname,ASCIIname);

     write('Make HTML file? (y/n)');
     readln(ans);
     if(ans in ['y','Y']) then
          MakeHTML(ASCIIname);

end.
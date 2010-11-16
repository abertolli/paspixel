program bmpnewpal;

{This program just tries to open a bmp file and rewrite it using the native pascal palette.}

uses crt;

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

	filename		: string;
	fileheader		: file of TBitmapInfo;
	info			: TBitmapInfo;
	loop			: integer;
	
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
end;{--------------------------------------------------------------------------}

begin

	{First we get the filename and check if it exists}
	repeat
		write('4-bit BMP to convert: ');
		readln(filename);
		if (not exists(filename)) then writeln('File not found.');
	until exists(filename);
	
	{Read in the file header data}
	assign(fileheader,filename);
	reset(fileheader);
	read(fileheader,info);
	close(fileheader);

	with info do
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

	
	{Write the information to screen, including the original palette}
	
	{Ask for an output filename and make sure it doesn't exist}
	
	{Change the record in memory to the new palette}
	
	{Write the header to the new file}
	
	{Read the pixel data from the original file, convert to the new palette, and write to the new file}

end.
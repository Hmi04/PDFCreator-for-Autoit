#include <MsgBoxConstants.au3>
#include <WinAPIFiles.au3>
#include <Array.au3>

ConsoleWrite(PDFGetData('a',33)&@LF)
$string=''
Local $hFileOpen = FileOpen(@ScriptDir&'\a.pdf', $FO_OVERWRITE)
$string=$string&PDFGetData('a',33)

FileWrite($hFileOpen, PDFOutput($string,12,612,792,42,4))
FileClose($hFileOpen)
;_ArrayDisplay($aa)
;ShellExecute('C:\Windows\pdfedit.exe','a.pdf')
ShellExecute('a.pdf')

Func Display($sInput, $sOutput)
    ; Format the output.
    Local $sMsg = StringFormat("Input:\t%s\n\nOutput:\t%s", $sInput, $sOutput)
    MsgBox($MB_SYSTEMMODAL, "Results", $sMsg)
EndFunc   ;==>Display


Func PDFGetData($file,$linecols)
   ;MsgBox('','',$pagetemplate)
    Local $hFileOpen = FileOpen(@ScriptDir&'\'&$file&'.txt', $FO_READ)
    If $hFileOpen = -1 Then
        Return ''
    EndIf
    Local $sFileRead = FileRead($hFileOpen)
    FileClose($hFileOpen)
   ;$sFileRead=StringRegExpReplace($sFileRead,'(.{0,'&$linecols&'}.[\W])', '$1'&@LF);|[\N]

   Return $sFileRead
EndFunc

Func PDFTemplate($pagetemplate,$pagenum)
   ;MsgBox('','',$pagetemplate)
    Local $hFileOpen = FileOpen(@ScriptDir&'\'&$pagetemplate&'.txt', $FO_READ)
    If $hFileOpen = -1 Then
        Return ''
    EndIf
    Local $sFileRead = FileRead($hFileOpen)
    FileClose($hFileOpen)
   Return StringReplace($sFileRead,'Page: XX','Page: '&$pagenum)
EndFunc

Func PDFOutput($sourcetext,$fontsize,$pagewidth,$pageheight,$leftmargin,$linenumberoffset)
$splitstring=StringSplit($sourcetext,@LF)
$splitstringlen=UBound($splitstring)
$numpages=Ceiling(($fontsize*$splitstringlen)/($pageheight/$fontsize)/$fontsize)-1
;MsgBox('','',($fontsize*$splitstringlen))
Local $xrefpage[$numpages+1],$xreffont,$xreftext[$numpages+2];,$xreftable[$numpages*2]
Local $pagetemplatetext=''
$xrefstart=''
$creator='User'
$pdfheader='%PDF-1.0'&@LF&'%¿÷¢þ'
$10obj=@LF&'1 0 obj'&@LF&'<< /Pages 3 0 R /Type /Catalog >>'&@LF&'endobj'
$20obj=@LF&'2 0 obj'&@LF&'<< /Author ('&$creator&') /Creator ('&$creator&') /Producer ('&$creator&') /Subject () /Title () >>'&@LF&'endobj'
$xref30=15+StringLen($10obj)+StringLen($20obj)
$30obj=@LF&'3 0 obj'&@LF&'<< /Count '&$numpages+1&' /Kids 4 0 R /Type /Pages >>'&@LF&'endobj'
$40obj=''
$pageobj=''
$textobj=''
$xref40=$xref30+StringLen($30obj)-1
$fontobj=@LF&$numpages+5+2&' 0 obj'&@LF&'<< /BaseFont /Helvetica /Encoding /WinAnsiEncoding /Subtype /Type1 /Type /Font >>'&@LF&'endobj' ;should come after first object, and beFor e next page
$xreftableindex=''
$tableindex=@LF&'xref'&@LF&'0 '&(($numpages+1)*6)+2&@LF
$xreftable=''
$table='0000000000 65535 f'&@LF&'0000000015 00000 n'&@LF&'0000000064 00000 n'&@LF&StringTrimLeft(10000000000+$xref30,1)&' 00000 n'&@LF&StringTrimLeft(10000000000+$xref40+1,1)&' 00000 n'&@LF
$tailer=@LF&'trailer << /Info 2 0 R /Root 1 0 R /Size '&$numpages*2+6&' >> startxref'&@LF&'1026'&@LF&'%%EOF'

For $i=5 to $numpages+5 ;start at 5
   $40obj=$40obj&$i&' 0 R '
Next
$40obj=@LF&'4 0 obj'&@LF&'[ '&$40obj&']'&@LF&'endobj'
$offset=1
For $i=0 to $numpages ;50obj
   $xrefpage[$i]=$xref40+StringLen($40obj)+StringLen($pageobj)+1
   $table=$table&StringTrimLeft(10000000000+$xrefpage[$i],1)&' 00000 n'&@LF
   $pageobj=$pageobj&@LF&$i+5&' 0 obj'&@LF&'<< /Contents '&$i+$numpages+7-$offset&' 0 R /CropBox [ 0 0 612 792 ] /MediaBox [ 0 0 '&$pagewidth&' '&$pageheight&' ] /Parent 3 0 R /Resources << /Font << /FXF1 '&($numpages+7)&' 0 R >> >> /Rotate 0 /Type /Page >>'&@LF&'endobj'
   $offset=0
Next

$o=1
$x=0
$xsum=0
$overflowpage=''
For $i=0 to $numpages
   $pagetemplatetext=''
   if $overflowpage<>'' Then $pagetemplatetext=@LF&PDFTemplate($overflowpage,$i+1)
   $text='/DeviceRGB cs 0 0 0 scn /DeviceRGB CS 0 0 0 SCN /FXF1 '&$fontsize&' Tf 1 i '&$leftmargin&' '
   $fontsize=($fontsize)
   For $t=($pageheight-$fontsize)-($linenumberoffset*$fontsize) to ($linenumberoffset*$fontsize) Step -($fontsize)
	  $splitstring1=''
	  $splitstring1len=2
	  $outputstring=''
	  If StringInStr($splitstring[$o],'¿')>0 Then
		 $splitstring1=StringSplit($splitstring[$o]&'¿¿','¿')
		 $splitstring1len=UBound($splitstring1)+1
	  ElseIf StringInStr($splitstring[$o],'pagetemplate')>0 AND NOT @error Then
		 $pagetemplatetext=@LF&PDFTemplate(StringRegExpReplace($splitstring[$o],'pagetemplate:|:.*',''),$i+1)
		 $overflowpage=StringRegExpReplace($splitstring[$o],'pagetemplate:|.*:','')
		 ;MsgBox('','',$splitstring[$o])
	  Else
		$outputstring=$splitstring[$o]
	 EndIf
	  $j=1
	  $y=0
	  Do
		 if IsArray($splitstring1)=1 Then $outputstring=$splitstring1[$j]
		 if $t=($pageheight-$fontsize)-($linenumberoffset*$fontsize) AND $j=1 then
			$y=$t
			$x=0;10;back to start indent
			$xsum=0
			$text=$text&$y&' TD[('&$outputstring&')]TJ'
			;MsgBox('','',$y)
		 Else
			if IsArray($splitstring1)<>1 AND $j<>1 Then
				$y=$y-($fontsize)
				$x=0-$xsum
				$xsum=0

			 elseif $j>=$splitstring1len-3  then
			   $x=0-$xsum ;'¿' appended earlier
			   $xsum=0

			Else
				$y=0
				if $j<$splitstring1len-2  then
					$x=$splitstring1[$j+1];MsgBox('','',$splitstring1[$j+1]);
					$xsum=$xsum+$x
								   ;$text=$text&' '&'1 i '&$x&' '&$y&' TD[('&$outputstring&')]TJ'
				 EndIf

			EndIf
			if $j=1 Then
			   $y=$y-($fontsize)
			Else
			   $y=0
			EndIf
			$text=$text&' '&'1 i '&$x&' '&$y&' TD[('&$outputstring&')]TJ'
		 EndIf
		 $j+=2
	  Until $j>$splitstring1len-2

	  if $o<=$splitstringlen-2 then
		 $o+=1
	  Else
		 ExitLoop
	  EndIf
   Next
   $textlength=StringLen($text)+StringLen($pagetemplatetext)+6
   if $i=0 Then
	  $xreftext[$i]=$xref40+StringLen($40obj)+StringLen($pageobj)+1+StringLen($textobj)
	  $table=$table&StringTrimLeft(10000000000+$xreftext[$i],1)&' 00000 n'&@LF
	  $textobj=@LF&$i+$numpages+7-1&' 0 obj'&@LF&'<< /Length '&$textlength&' >>'&@LF&'stream'&$pagetemplatetext&@LF&'BT'&@LF&$text&@LF&'ET'&@LF&'endstream'&@LF&'endobj'
	  $xreffont=$xreftext[$i]+StringLen($textobj)
	  $textobj=$textobj&$fontobj
	  $table=$table&StringTrimLeft(10000000000+$xreffont,1)&' 00000 n'&@LF
	  $xreftext[$i+1]=$xreftext[$i]+StringLen($textobj)
   Else
	  $xreftext[$i+1]=$xreffont+StringLen($textobj)+1
	  $textobj=$textobj&@LF&$i+$numpages+7&' 0 obj'&@LF&'<< /Length '&$textlength&' >>'&@LF&'stream'&$pagetemplatetext&@LF&'BT'&@LF&$text&@LF&'ET'&@LF&'endstream'&@LF&'endobj'
	  $table=$table&StringTrimLeft(10000000000+$xreftext[$i],1)&' 00000 n'&@LF
   EndIf
Next
$startxref=$xreftext[0]+StringLen($textobj)
$tailer='trailer << /Info 2 0 R /Root 1 0 R /Size '&(($numpages+1)*6)+2&' >>'&@LF&'startxref'&@LF&$startxref&@LF&'%%EOF'

$pdfoutput=$pdfheader&$10obj&$20obj&$30obj&$40obj&$pageobj&$textobj&$tableindex&$table&$tailer
   ConsoleWrite($pdfoutput&@CRLF)
   Return $pdfoutput
EndFunc
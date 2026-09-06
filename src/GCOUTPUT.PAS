(* Разработка алгоритмов управления транспортной системой РТК галь- *)
(* ванопокрытий с использованием  методов ситуационного управления. *)
(* Вывод результатов *)

{$M $4000,0,20000}
Program GCOutput;
Uses
  TPCrt, TPDir, DOS, Printer, TPPick, TPString;
  const
   Colors : PickColorArray=($30, $7F, $7F, $2F, $0f, $0e);
  var
    C: byte;
    SC0: Pointer;
    FN: string;
  procedure PrintFile (FN: string);
    var
      f: text;
      s: string;
      i, NumberOfLines: word;
      NumberOfPaintedBoxes, NumberOfPaintedBoxes1: byte;
    begin
      Assign(f, FN); Reset(f);
      NumberOfLines:=1;
      While Not Eof(f) do begin inc(NumberOfLines); ReadLn(f); end;
      Close(f);
      FastCenter('®¬¥à à á¯¨á ­¨ï: '+Copy(JustFileName(FN),8,1), 3, $1F);
      Window(22,10,59,16);
      TextAttr:=$70; ClrScr;
      SetFrameChars('º', 'Í', '¼', '»', 'È', 'É');
      FrameWindow(23,10,58,16, $70, $70, ' ˆá¯®«­¥­¨¥ ');
      FastWriteWindow(CharStr('°', 30), 4, 5, $70);
      HiddenCursor;
      Reset(f);
      NumberOfPaintedBoxes1:=0;
      For i:=1 to NumberOfLines do
        begin
        NumberOfPaintedBoxes:=Round(30*i/NumberOfLines);
        If NumberOfPaintedBoxes<>NumberOfPaintedBoxes1 then
          begin
          NumberOfPaintedBoxes1:=NumberOfPaintedBoxes;
          FastWriteWindow(CharStr('Û', NumberOfPaintedBoxes), 4, 5, $70);
          end;
        ReadLn(f,s); {WriteLn(lst, s);}
        end;
      Write('');{ Write(lst, $FF);} Close(f);
    end;

  begin
    WriteLn (' á¯¨á ­¨¥ à ¡®âë âà ­á¯®àâ­®© á¨áâ¥¬ë ’Š £ «ì¢ ­®¯®ªàëâ¨©',
            #10, #13, '‚ë¢®¤ à¥§ã«ìâ â®¢',
            #10, #13, 'Œ¥¦ã¥¢ €., ‘€, ’ˆ•Œ, 1992, 93');
    SaveWindow(1,2,80,25,TRUE,SC0); C:=TextAttr;
    Repeat
      TextAttr:=$1F; ClrScr;
      FastWrite('                                ‚ë¢®¤ à¥§ã«ìâ â®¢                               ',1,1,$4F);
      GetFileName('program?.dat',$20, 25, 10, 22, 2, Colors, FN);
      If FN<>'' then PrintFile (FN);
    Until FN='';
    TextAttr:=C; ClrScr; RestoreWindow(1,1,80,24,TRUE,SC0);
  end.

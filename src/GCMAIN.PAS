(* Разработка алгоритмов управления транспортной системой РТК галь- *)
(* ванопокрытий с использованием  методов ситуационного управления. *)
(* Главный модуль *)

{$M $4000,0,20000}
Program GCMain;
Uses
  DOS, TPString, TPCrt, TPCmd, TPWindow, TPMenu;

procedure InitMenu(var M : Menu);
const
  Color1 : MenuColorArray = ($1F, $2E, $1F, $3F, $1E, $11, $19, $78);
  Frame1 : FrameArray = 'ÉÈ»¼Íº';
begin
  M := NewMenu([], nil);
  SubMenu(24,9,25,Vertical,Frame1,Color1,'');
    MenuMode(True, False, False);
    MenuItem('‚¢®¤ ¤ ­­ëå',1,1,1,CharStr('a',80));
    MenuItem(' áç¥â à á¯¨á ­¨ï ¤¢¨¦¥­¨ï',2,1,2,CharStr(' ',80));
    MenuItem('¥ç âì à á¯¨á ­¨ï ¤¢¨¦¥­¨ï',3,1,3,CharStr(' ',80));
    MenuItem('ƒà ä¨ç¥áª®¥ ¨««îáâà¨à®¢ ­¨¥',4,1,4,CharStr(' ',80));
    MenuItem('“¯à ¢«¥­¨¥ ¬¨ªà®ª®­âà®««¥à®¬',5,1,4,CharStr(' ',80));
    MenuItem('‚ëå®¤',6,1,6,CharStr(' ',80));
    PopSublevel;
  ResetMenu(M);
 SetMenuDelay(M, 10);
end;

procedure ErrorMessage;
  var
   C: byte;
   ch: char;
   S: Pointer;
  begin
    SaveWindow(20,13,60,18,TRUE,S); C:=TextAttr;
    Window(20,13,60,18); TextAttr:=$4E; ClrScr;
    SetFrameChars('³', 'Ä', 'Ù', '¿', 'À', 'Ú');
    FrameWindow(20,13,60,18, $4F, $4E, ' Žè¨¡ª  ');
    FastCenter('¥¤®áâ â®ª ¯ ¬ïâ¨', 3, $4E);
    HiddenCursor;
    ch:=ReadKey; write ('');
    TextAttr:=C; RestoreWindow(20,13,60,18,TRUE,S);
  end;

var
  SC0: Pointer;
  M : Menu;
  Ch : Char;
  C: byte;
  Key : MenuKey;

begin
  WriteLn (' á¯¨á ­¨¥ à ¡®âë âà ­á¯®àâ­®© á¨áâ¥¬ë ’Š £ «ì¢ ­®¯®ªàëâ¨©',
          #10, #13, 'Œ¥¦ã¥¢ €., ‘€, ’ˆ•Œ, 1992, 93');
  SaveWindow(1,2,80,25,TRUE,SC0); C:=TextAttr;
  InitMenu(M);
  Repeat
    TextAttr:=$1F; ClrScr;
    FastWrite('            á¯¨á ­¨¥ à ¡®âë âà ­á¯®àâ­®© á¨áâ¥¬ë ’Š £ «ì¢ ­®¯®ªàëâ¨©          ',1,1,$4F);
    Key := MenuChoice(M, Ch);
    If Ch<>#27 then
      begin
        DOSError:=0;
        EraseMenu(M, False);
        Case Key of
          1: Exec ('gcentry.exe', '');
          2: Exec ('gc.exe', '');
          3: Exec ('gcoutput.exe', '');
          4: Exec ('gcg.exe', '');
          5: Exec ('gc_mc.exe', '');
        end;
        If DOSError=8 then ErrorMessage;
      end
  until (Ch=#27) OR (Key=6);
  TextAttr:=C; ClrScr; RestoreWindow(1,1,80,24,TRUE,SC0);
end.

(* Разработка алгоритмов управления транспортной системой РТК галь- *)
(* ванопокрытий с использованием  методов ситуационного управления. *)
(* Инсталлирующий модуль *)

{$M $4000,0,20000}
Program GC_Installator;
  uses DOS;
  var
    f_set: text;
  begin
     Assign (f_set, 'gcset.dat'); Rewrite (f_set);
     Write (f_set, '1 2 1 0 1 1');
     Close (f_set);
     Exec ('gc.exe', '');
end.



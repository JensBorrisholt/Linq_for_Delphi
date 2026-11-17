program LazyQueries;
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  Aegis.Generics.Collections in '..\Aegis.Generics.Collections.pas',
  System.Linq in '..\System.Linq.pas';

// Demonstrate deferred query execution and materialisation.
procedure Run;
begin
  var Values := TList<Integer>.New([1, 2, 3, 4]);   // IList<Integer>

  var Lazy := Linq.From<Integer>(Values).Where   // nothing runs yet
  (
    function(V: Integer): Boolean
    begin
      Result := V mod 2 = 0;
    end
  );

  var Snapshot := Lazy.ToList;   // runs now: IList<Integer>

  Values.Add(6);
  WriteLn('Snapshot (before Add):');
  for var N in Snapshot do
    WriteLn('  ', N);

  WriteLn('Lazy sequence (after Add):');
  for var N in Lazy do   // runs again and sees the 6
    WriteLn('  ', N);

  var FirstTwo := Linq.From<Integer>(Values)
  .Where
  (
    function(V: Integer): Boolean
    begin
      Result := V > 2;
    end
  )
  .Take(2);

  WriteLn('First 2 numbers > 2:');
  for var N in FirstTwo do
    WriteLn('  ', N);
end;

begin
  ReportMemoryLeaksOnShutdown := True;
  try
    Run;
    ReadLn;
  except
    on E: Exception do
      WriteLn(E.ClassName + ': ' + E.Message);
  end;
end.

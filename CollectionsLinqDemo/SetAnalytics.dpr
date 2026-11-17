program SetAnalytics;
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  Aegis.Generics.Collections in '..\Aegis.Generics.Collections.pas',
  System.Linq in '..\System.Linq.pas';

// Compare two sets; continue querying them through IEnumerable<T>.
procedure Run;
begin
  var TeamA := THashSet<Integer>.New([10, 20, 30, 40]);
  var TeamB := THashSet<Integer>.New([20, 40, 50]);

  var Shared := Linq.From<Integer>(TeamA).Intersect(TeamB).OrderBy<Integer>
  (
    function(V: Integer): Integer
    begin
      Result := V;
    end
  );
  var OnlyA := Linq.From<Integer>(TeamA).&Except(TeamB).OrderBy<Integer>
  (
    function(V: Integer): Integer
    begin
      Result := V;
    end
  );

  WriteLn('In both teams:');
  for var N in Shared do
    WriteLn('  ', N);
  WriteLn('Only team A:');
  for var N in OnlyA do
    WriteLn('  ', N);
  WriteLn('Distinct across both: ', Linq.From<Integer>(TeamA).Union(TeamB).Count);
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

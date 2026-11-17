program ZipColumns;
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  Aegis.Generics.Collections in '..\Aegis.Generics.Collections.pas',
  System.Linq in '..\System.Linq.pas';

procedure Run;
begin
  var Names := TList<string>.New(['Anna', 'Bo', 'Clara']);
  var Scores := TList<Integer>.New([90, 75]);

  // Zip ends when the shorter sequence ends.
  var Rows := Linq.From<string>(Names).Zip<Integer, string>
  (
    Scores,
    function(Name: string; Score: Integer): string
    begin
      Result := Name + ': ' + IntToStr(Score);
    end
  );

  WriteLn('Scores:');
  for var Row in Rows do
    WriteLn('  ' + Row);
  WriteLn('Rows: ', Rows.Count);
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

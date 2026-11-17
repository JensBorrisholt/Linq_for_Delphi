program SelectManyGroups;
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  Aegis.Generics.Collections in '..\Aegis.Generics.Collections.pas',
  System.Linq in '..\System.Linq.pas';

type
  TTeam = record
    Name: string;
    Members: IList<string>;
  end;

function MakeTeam(const AName: string; const A, B: string): TTeam;
begin
  Result.Name := AName;
  Result.Members := TList<string>.New([A, B]);
end;

procedure Run;
begin
  var Teams := TList<TTeam>.New;
  Teams.Add(MakeTeam('Backend', 'Anna', 'Bo'));
  Teams.Add(MakeTeam('Frontend', 'Clara', 'David'));

  // One input team yields two members: flatten two nested sequences.
  var AllNames := Linq.From<TTeam>(Teams).SelectMany<string>
  (
    function(Team: TTeam): IEnumerable<string>
    begin
      Result := Team.Members;
    end
  );

  WriteLn('Members:');
  for var Name in AllNames do
    WriteLn('  ' + Name);
  WriteLn('Total: ', AllNames.Count);
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

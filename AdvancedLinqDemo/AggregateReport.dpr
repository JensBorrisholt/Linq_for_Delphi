program AggregateReport;
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  Aegis.Generics.Collections in '..\Aegis.Generics.Collections.pas',
  System.Linq in '..\System.Linq.pas';

procedure Run;
begin
  var Amounts := TList<Integer>.New([120, 80, 200]);

  var Total := Linq.From<Integer>(Amounts).Aggregate<Integer>
  (
    0,
    function(Acc, Value: Integer): Integer
    begin
      Result := Acc + Value;
    end
  );
  var Maximum := Linq.From<Integer>(Amounts).Aggregate<Integer>
  (
    0,
    function(Acc, Value: Integer): Integer
    begin
      if Value > Acc then Result := Value else Result := Acc;
    end
  );
  var Description := Linq.From<Integer>(Amounts).Aggregate<string>
  (
    '',
    function(Acc: string; Value: Integer): string
    begin
      if Acc = '' then Result := IntToStr(Value)
      else Result := Acc + ', ' + IntToStr(Value);
    end
  );

  WriteLn('Amounts: ' + Description);
  WriteLn('Total: ', Total);
  WriteLn('Maximum: ', Maximum);
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

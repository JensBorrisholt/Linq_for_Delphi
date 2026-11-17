program OrdersPipeline;
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  Aegis.Generics.Collections in '..\Aegis.Generics.Collections.pas',
  System.Linq in '..\System.Linq.pas';

type
  TOrder = record
    Number: Integer;
    Customer: string;
    Amount: Integer;
    Paid: Boolean;
  end;

function MakeOrder(ANumber: Integer; const ACustomer: string;
  AAmount: Integer; APaid: Boolean): TOrder;
begin
  Result.Number := ANumber;
  Result.Customer := ACustomer;
  Result.Amount := AAmount;
  Result.Paid := APaid;
end;

procedure Run;
begin
  var Orders := TList<TOrder>.New;
  Orders.Add(MakeOrder(1001, 'Anna', 400, False));
  Orders.Add(MakeOrder(1002, 'Bo', 150, True));
  Orders.Add(MakeOrder(1003, 'Anna', 225, False));
  Orders.Add(MakeOrder(1004, 'Carl', 500, False));

  var Outstanding := Linq.From<TOrder>(Orders)
  .Where
  (
    function(O: TOrder): Boolean
    begin
      Result := not O.Paid;
    end
  )
  .OrderByDescending<Integer>
  (
    function(O: TOrder): Integer
    begin
      Result := O.Amount;
    end
  );

  WriteLn('Unpaid orders (largest first):');
  for var Order in Outstanding do
    WriteLn('  #', Order.Number, ' ', Order.Customer, ' ', Order.Amount);

  var Total := Outstanding.Sum<Integer>
  (
    function(O: TOrder): Integer
    begin
      Result := O.Amount;
    end
  );
  WriteLn('Outstanding amount: ', Total);

  var HasUnpaid := Linq.From<TOrder>(Orders).Any
  (
    function(O: TOrder): Boolean
    begin
      Result := not O.Paid;
    end
  );
  WriteLn('Has unpaid orders: ', BoolToStr(HasUnpaid, True));
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

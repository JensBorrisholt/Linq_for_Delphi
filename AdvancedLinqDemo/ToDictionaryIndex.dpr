program ToDictionaryIndex;
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  Aegis.Generics.Collections in '..\Aegis.Generics.Collections.pas',
  System.Linq in '..\System.Linq.pas';

type
  TProduct = record
    Code: Integer;
    Name: string;
    Price: Integer;
  end;

function Product(ACode: Integer; const AName: string; APrice: Integer): TProduct;
begin
  Result.Code := ACode;
  Result.Name := AName;
  Result.Price := APrice;
end;

procedure Run;
begin
  var Products := TList<TProduct>.New;
  Products.Add(Product(101, 'Keyboard', 300));
  Products.Add(Product(102, 'Mouse', 150));
  Products.Add(Product(103, 'Monitor', 1800));

  // Single selector retains entire record as dictionary value.
  var ByCode := Linq.From<TProduct>(Products).ToDictionary<Integer>
  (
    function(P: TProduct): Integer
    begin
      Result := P.Code;
    end
  );

  // Two selectors choose both key and value type.
  var Prices := Linq.From<TProduct>(Products).ToDictionary<Integer, Integer>
  (
    function(P: TProduct): Integer
    begin
      Result := P.Code;
    end,
    function(P: TProduct): Integer
    begin
      Result := P.Price;
    end
  );

  var Found: TProduct;
  if ByCode.TryGetValue(102, Found) then
    WriteLn('Product 102: ' + Found.Name);
  var Price: Integer;
  if Prices.TryGetValue(103, Price) then
    WriteLn('Price 103: ', Price);
  WriteLn('Entries: ', ByCode.Count);
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

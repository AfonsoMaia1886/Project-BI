[StagingDefinition = [Kind = "FastCopy"]]
section Section1;
shared DimProduct = let
    Source = Lakehouse.Contents(null),
    Navigation = Source{[workspaceId = "b7626cf0-cc95-4e17-9611-abea9e945cb8"]}[Data],
    #"Navigation 1" = Navigation{[lakehouseId = "b90961d6-ba06-4fde-834e-3b465d913510"]}[Data],
    #"Navigation 2" = #"Navigation 1"{[Id = "Files", ItemKind = "Folder"]}[Data],
    #"Navigation 3" = #"Navigation 2"{[Name = "Products.csv"]}[Content],

    #"Imported CSV" =
        Csv.Document(
            #"Navigation 3",
            [Delimiter = ",", Columns = 6, Encoding = 1252, QuoteStyle = QuoteStyle.None]
        ),

    #"Renamed columns" =
        Table.RenameColumns(
            #"Imported CSV",
            {
                {"Column1", "CNP"},
                {"Column2", "ProductName"},
                {"Column3", "Manufacturer"},
                {"Column4", "Brand"},
                {"Column5", "ProductPresentation"},
                {"Column6", "GenericRaw"}
            }
        ),

    CleanText = (x as any) as nullable text =>
        if x = null then null else Text.Trim(Text.From(x)),

    ToCNPNumber = (x as any) as nullable number =>
        let
            t = CleanText(x),
            base = if t = null then null else if Text.Contains(t, ".") then Text.BeforeDelimiter(t, ".") else t,
            result = if base = null or base = "" then null else try Int64.From(Number.FromText(base, "en-US")) otherwise null
        in
            result,

    FirstNonNull = (lst as list) as nullable text =>
        let
            clean = List.RemoveNulls(lst)
        in
            if List.Count(clean) = 0 then null else clean{0},

    #"Changed column type" =
        Table.TransformColumnTypes(
            #"Renamed columns",
            {
                {"CNP", type text},
                {"ProductName", type text},
                {"Manufacturer", type text},
                {"Brand", type text},
                {"ProductPresentation", type text},
                {"GenericRaw", type text}
            },
            "pt"
        ),

    #"Cleaned text" =
        Table.TransformColumns(
            #"Changed column type",
            {
                {"CNP", each CleanText(_), type text},
                {"ProductName", each CleanText(_), type text},
                {"Manufacturer", each CleanText(_), type text},
                {"Brand", each CleanText(_), type text},
                {"ProductPresentation", each CleanText(_), type text},
                {"GenericRaw", each if _ = null then null else Text.Upper(CleanText(_)), type text}
            }
        ),

    #"Removed blank rows" =
        Table.SelectRows(
            #"Cleaned text",
            each [CNP] <> null
                and [CNP] <> ""
                and [ProductName] <> null
                and [ProductName] <> ""
        ),

    #"Added GenericLabel" =
        Table.AddColumn(
            #"Removed blank rows",
            "GenericLabel",
            each
                if [GenericRaw] = "Y" or [GenericRaw] = "S" then "Generic"
                else if [GenericRaw] = "N" then "Branded"
                else "Unknown",
            type text
        ),

    #"Grouped products" =
        Table.Group(
            #"Added GenericLabel",
            {"CNP"},
            {
                {"ProductName", each FirstNonNull([ProductName]), type text},
                {"Manufacturer", each FirstNonNull([Manufacturer]), type text},
                {"Brand", each FirstNonNull([Brand]), type text},
                {"ProductPresentation", each FirstNonNull([ProductPresentation]), type text},
                {"GenericLabel", each
                    let
                        statuses = List.Distinct([GenericLabel])
                    in
                        if List.Count(statuses) = 1 then statuses{0} else "Unknown",
                    type text
                }
            }
        ),

    #"Converted CNP to number" =
        Table.TransformColumns(
            #"Grouped products",
            {
                {"CNP", each ToCNPNumber(_), Int64.Type}
            }
        ),

    #"Removed invalid CNP rows" =
        Table.SelectRows(
            #"Converted CNP to number",
            each [CNP] <> null
        ),

    #"Added ProductKey" =
        Table.AddIndexColumn(
            #"Removed invalid CNP rows",
            "ProductKey",
            1,
            1,
            Int64.Type
        ),

    #"Added IsGeneric" =
        Table.AddColumn(
            #"Added ProductKey",
            "IsGeneric",
            each [GenericLabel] = "Generic",
            type logical
        ),

    #"Reordered columns" =
        Table.ReorderColumns(
            #"Added IsGeneric",
            {
                "ProductKey",
                "CNP",
                "ProductName",
                "Manufacturer",
                "Brand",
                "ProductPresentation",
                "IsGeneric",
                "GenericLabel"
            }
        ),

    #"Unknown product row" =
        #table(
            type table
            [
                ProductKey = Int64.Type,
                CNP = Int64.Type,
                ProductName = text,
                Manufacturer = text,
                Brand = text,
                ProductPresentation = text,
                IsGeneric = logical,
                GenericLabel = text
            ],
            {
                {-1, -1, "Unknown Product", "Unknown", "Unknown", "Unknown", false, "Unknown"}
            }
        ),

    #"Final table" =
        Table.Combine(
            {
                #"Unknown product row",
                #"Reordered columns"
            }
        ),

    #"Final column types" =
        Table.TransformColumnTypes(
            #"Final table",
            {
                {"ProductKey", Int64.Type},
                {"CNP", Int64.Type},
                {"ProductName", type text},
                {"Manufacturer", type text},
                {"Brand", type text},
                {"ProductPresentation", type text},
                {"IsGeneric", type logical},
                {"GenericLabel", type text}
            },
            "pt"
        ),
  #"Renamed columns 1" = Table.RenameColumns(#"Final column types", {{"ProductKey", "SK_Product"}})
in
    #"Renamed columns 1";
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "FactSales_DataDestination", IsNewTarget = false], Settings = [Kind = "Manual", AllowCreation = false, ColumnSettings = [Mappings = {[SourceColumnName = "PK_SaleID", DestinationColumnName = "PK_SaleID"], [SourceColumnName = "FK_Date", DestinationColumnName = "FK_Date"], [SourceColumnName = "FK_Time", DestinationColumnName = "FK_Time"], [SourceColumnName = "FK_Product", DestinationColumnName = "FK_Product"], [SourceColumnName = "FK_Pharmacy", DestinationColumnName = "FK_Pharmacy"], [SourceColumnName = "FK_Location", DestinationColumnName = "FK_Location"], [SourceColumnName = "FK_Operator", DestinationColumnName = "FK_Operator"], [SourceColumnName = "FK_POS", DestinationColumnName = "FK_POS"], [SourceColumnName = "Qty", DestinationColumnName = "Qty"], [SourceColumnName = "Amount", DestinationColumnName = "Amount"], [SourceColumnName = "CurrencyCode", DestinationColumnName = "CurrencyCode"], [SourceColumnName = "SourceSaleDateTime", DestinationColumnName = "SourceSaleDateTime"], [SourceColumnName = "LoadDateTime", DestinationColumnName = "LoadDateTime"]}], DynamicSchema = false, UpdateMethod = [Kind = "Replace"], TypeSettings = [Kind = "Table"]]]}]
shared FactSales = let
    Source = Lakehouse.Contents(null),
    Navigation = Source{[workspaceId = "b7626cf0-cc95-4e17-9611-abea9e945cb8"]}[Data],
    #"Navigation 1" = Navigation{[lakehouseId = "b90961d6-ba06-4fde-834e-3b465d913510"]}[Data],
    #"Navigation 2" = #"Navigation 1"{[Id = "Files", ItemKind = "Folder"]}[Data],
    #"Navigation 3" = #"Navigation 2"{[Name = "Sales (Pharmacy).csv"]}[Content],

    #"Imported CSV" =
        Csv.Document(
            #"Navigation 3",
            [Delimiter = ",", Columns = 10, Encoding = 65001, QuoteStyle = QuoteStyle.None]
        ),

    #"Promoted headers" =
        Table.PromoteHeaders(
            #"Imported CSV",
            [PromoteAllScalars = true]
        ),

    #"Renamed columns" =
        Table.RenameColumns(
            #"Promoted headers",
            {
                {"Sale ID", "SaleID"},
                {"Datetime", "SourceSaleDateTimeText"},
                {"Pharmacy", "FK_Pharmacy"},
                {"POS", "FK_POS"},
                {"Localização", "FK_Location"},
                {"Currency", "CurrencyCode"},
                {"operator_id", "FK_Operator"}
            }
        ),

    CleanText = (x as any) as nullable text =>
        if x = null then null else Text.Trim(Text.From(x)),

    ToInt64 = (x as any) as nullable number =>
        let
            t = CleanText(x),
            result = if t = null or t = "" then null else try Int64.From(Number.FromText(t, "en-US")) otherwise null
        in
            result,

    ToDecimal = (x as any) as nullable number =>
        let
            t = CleanText(x),
            result = if t = null or t = "" then null else try Number.FromText(t, "en-US") otherwise null
        in
            result,

    ToCNPNumber = (x as any) as nullable number =>
        let
            t = CleanText(x),
            base = if t = null then null else if Text.Contains(t, ".") then Text.BeforeDelimiter(t, ".") else t,
            result = if base = null or base = "" then null else try Int64.From(Number.FromText(base, "en-US")) otherwise null
        in
            result,

    ParseDateTime = (x as any) as nullable datetime =>
        let
            t = CleanText(x),
            parts = if t = null then null else Text.Split(t, " "),
            dateParts = if parts = null or List.Count(parts) < 1 then null else Text.Split(parts{0}, "/"),
            timeParts = if parts = null or List.Count(parts) < 2 then {"0", "0"} else Text.Split(parts{1}, ":"),
            result =
                try
                    #datetime(
                        Int64.From(dateParts{2}),
                        Int64.From(dateParts{1}),
                        Int64.From(dateParts{0}),
                        Int64.From(timeParts{0}),
                        Int64.From(timeParts{1}),
                        0
                    )
                otherwise null
        in
            result,

    #"Changed main types" =
        Table.TransformColumns(
            #"Renamed columns",
            {
                {"SaleID", each ToInt64(_), Int64.Type},
                {"SourceSaleDateTimeText", each CleanText(_), type text},
                {"CNP", each ToCNPNumber(_), Int64.Type},
                {"FK_Pharmacy", each ToInt64(_), Int64.Type},
                {"FK_POS", each ToInt64(_), Int64.Type},
                {"FK_Location", each ToInt64(_), Int64.Type},
                {"CurrencyCode", each CleanText(_), type text},
                {"Qty", each ToInt64(_), Int64.Type},
                {"Amount", each ToDecimal(_), type number},
                {"FK_Operator", each ToInt64(_), Int64.Type}
            }
        ),

    #"Added SourceSaleDateTime" =
        Table.AddColumn(
            #"Changed main types",
            "SourceSaleDateTime",
            each ParseDateTime([SourceSaleDateTimeText]),
            type datetime
        ),

    #"Removed invalid rows" =
        Table.SelectRows(
            #"Added SourceSaleDateTime",
            each [SaleID] <> null
                and [SourceSaleDateTime] <> null
                and [FK_Pharmacy] <> null
                and [FK_POS] <> null
                and [FK_Location] <> null
                and [FK_Operator] <> null
                and [Qty] <> null
                and [Amount] <> null
        ),

    #"Added SaleKey" =
        Table.AddColumn(
            #"Removed invalid rows",
            "SaleKey",
            each [SaleID],
            Int64.Type
        ),

    #"Added FK_Date" =
        Table.AddColumn(
            #"Added SaleKey",
            "FK_Date",
            each
                Date.Year(Date.From([SourceSaleDateTime])) * 10000
                + Date.Month(Date.From([SourceSaleDateTime])) * 100
                + Date.Day(Date.From([SourceSaleDateTime])),
            Int64.Type
        ),

    #"Added FK_Time" =
        Table.AddColumn(
            #"Added FK_Date",
            "FK_Time",
            each
                Time.Hour(Time.From([SourceSaleDateTime])) * 100
                + Time.Minute(Time.From([SourceSaleDateTime])),
            Int64.Type
        ),

    #"Added CNPForJoin" =
        Table.AddColumn(
            #"Added FK_Time",
            "CNPForJoin",
            each if [CNP] = null then -1 else [CNP],
            Int64.Type
        ),

    DimProductLookup =
        Table.Buffer(
            Table.SelectColumns(
                DimProduct,
                {"CNP", "SK_Product"}
            )
        ),

    #"Merged with DimProduct" =
        Table.NestedJoin(
            #"Added CNPForJoin",
            {"CNPForJoin"},
            DimProductLookup,
            {"CNP"},
            "DimProductLookup",
            JoinKind.LeftOuter
        ),

    #"Expanded FK_Product" =
        Table.ExpandTableColumn(
            #"Merged with DimProduct",
            "DimProductLookup",
            {"SK_Product"},
            {"FK_Product"}
        ),

    #"Handled missing FK_Product" =
        Table.ReplaceValue(
            #"Expanded FK_Product",
            null,
            -1,
            Replacer.ReplaceValue,
            {"FK_Product"}
        ),

    #"Added LoadDateTime" =
        Table.AddColumn(
            #"Handled missing FK_Product",
            "LoadDateTime",
            each DateTime.LocalNow(),
            type datetime
        ),

    #"Selected final columns" =
        Table.SelectColumns(
            #"Added LoadDateTime",
            {
                "SaleKey",
                "SaleID",
                "FK_Date",
                "FK_Time",
                "FK_Product",
                "FK_Pharmacy",
                "FK_Location",
                "FK_Operator",
                "FK_POS",
                "Qty",
                "Amount",
                "CurrencyCode",
                "SourceSaleDateTime",
                "LoadDateTime"
            }
        ),

    #"Final column types" =
        Table.TransformColumnTypes(
            #"Selected final columns",
            {
                {"SaleKey", Int64.Type},
                {"SaleID", Int64.Type},
                {"FK_Date", Int64.Type},
                {"FK_Time", Int64.Type},
                {"FK_Product", Int64.Type},
                {"FK_Pharmacy", Int64.Type},
                {"FK_Location", Int64.Type},
                {"FK_Operator", Int64.Type},
                {"FK_POS", Int64.Type},
                {"Qty", Int64.Type},
                {"Amount", type number},
                {"CurrencyCode", type text},
                {"SourceSaleDateTime", type datetime},
                {"LoadDateTime", type datetime}
            },
            "pt"
        ),
  #"Renamed columns 1" = Table.RenameColumns(#"Final column types", {{"SaleKey", "PK_SaleID"}}),
  #"Filtered Incremental Rows" = Table.SelectRows(#"Renamed columns 1", each [PK_SaleID] > Number.From(p_LastSaleID)),
  #"Removed columns" = Table.RemoveColumns(#"Filtered Incremental Rows", {"SaleID"})
in
    #"Removed columns";
shared p_LastSaleID = 0 meta [IsParameterQuery = true, IsParameterQueryRequired = true, Type = type number];
shared FactSales_DataDestination = let
  Pattern = Fabric.Warehouse([CreateNavigationProperties = false, HierarchicalNavigation = true]),
  Navigation_1 = Pattern{[workspaceId = "b7626cf0-cc95-4e17-9611-abea9e945cb8"]}[Data],
  Navigation_2 = Navigation_1{[warehouseId = "31a736e4-406e-4dbb-8ee0-2354785b3f85"]}[Data],
  Navigation_3 = Navigation_2{[Schema = "dwh"]}[Data],
  TableNavigation = Navigation_3{[Name = "FactSales"]}[Data]
in
  TableNavigation;

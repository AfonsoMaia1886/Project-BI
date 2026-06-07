[DefaultOutputDestinationSettings = [DestinationDefinition = [Kind = "Reference", QueryName = "DefaultDestination", IsNewTarget = true], UpdateMethod = [Kind = "Append"], DestinationTypeSettings = [Kind = "Table"]], StagingDefinition = [Kind = "FastCopy"]]
section Section1;
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "DimPOS_DataDestination", IsNewTarget = false], Settings = [Kind = "Manual", AllowCreation = false, ColumnSettings = [Mappings = {[SourceColumnName = "SK_Pos", DestinationColumnName = "SK_POS"], [SourceColumnName = "POSName", DestinationColumnName = "POSName"], [SourceColumnName = "POSEmail", DestinationColumnName = "POSEmail"]}], DynamicSchema = false, UpdateMethod = [Kind = "Replace"], TypeSettings = [Kind = "Table"]]]}]
shared DimPOS = let
  Source = Lakehouse.Contents(null),
  Navigation = Source{[workspaceId = "b7626cf0-cc95-4e17-9611-abea9e945cb8"]}[Data],
  #"Navigation 1" = Navigation{[lakehouseId = "b90961d6-ba06-4fde-834e-3b465d913510"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[Id = "Files", ItemKind = "Folder"]}[Data],
  #"Navigation 3" = #"Navigation 2"{[Name = "Point of Supply.csv"]}[Content],
  #"Imported CSV" = Csv.Document(#"Navigation 3", [Delimiter = ",", Columns = 3, QuoteStyle = QuoteStyle.None]),
  #"Promoted headers" = Table.PromoteHeaders(#"Imported CSV", [PromoteAllScalars = true]),
  #"Renamed columns" = Table.RenameColumns(#"Promoted headers", {{"POS id", "POSID"}}),
  #"Changed column type" = Table.TransformColumnTypes(#"Renamed columns", {{"POSID", Int64.Type}, {"name", type text}, {"email", type text}}, "pt"),
  #"Renamed columns 1" = Table.RenameColumns(#"Changed column type", {{"name", "POSName"}, {"email", "POSEmail"}}),
  #"Changed column type 1" = Table.TransformColumnTypes(#"Renamed columns 1", {{"POSID", Int64.Type}}),
  #"Duplicated column" = Table.DuplicateColumn(#"Changed column type 1", "POSID", "POSID - Copy"),
  #"Reordered columns" = Table.ReorderColumns(#"Duplicated column", {"POSID - Copy", "POSID", "POSName", "POSEmail"}),
  #"Renamed columns 2" = Table.RenameColumns(#"Reordered columns", {{"POSID - Copy", "SK_Pos"}}),
  #"Removed columns" = Table.RemoveColumns(#"Renamed columns 2", {"POSID"})
in
  #"Removed columns";
shared DefaultDestination = Fabric.Warehouse([CreateNavigationProperties = false]){[workspaceId = "b7626cf0-cc95-4e17-9611-abea9e945cb8"]}[Data]{[warehouseId = "31a736e4-406e-4dbb-8ee0-2354785b3f85"]}[Data];
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "DimOperator_DataDestination", IsNewTarget = false], Settings = [Kind = "Manual", AllowCreation = false, ColumnSettings = [Mappings = {[SourceColumnName = "SK_Operator", DestinationColumnName = "SK_Operator"], [SourceColumnName = "FirstName", DestinationColumnName = "FirstName"], [SourceColumnName = "LastName", DestinationColumnName = "LastName"], [SourceColumnName = "FullName", DestinationColumnName = "FullName"], [SourceColumnName = "Email", DestinationColumnName = "Email"], [SourceColumnName = "Gender", DestinationColumnName = "Gender"], [SourceColumnName = "Role", DestinationColumnName = "Role"], [SourceColumnName = "Team", DestinationColumnName = "Team"]}], DynamicSchema = false, UpdateMethod = [Kind = "Replace"], TypeSettings = [Kind = "Table"]]]}]
shared DimOperator = let
  Source = Lakehouse.Contents(null),
  Navigation = Source{[workspaceId = "b7626cf0-cc95-4e17-9611-abea9e945cb8"]}[Data],
  #"Navigation 1" = Navigation{[lakehouseId = "b90961d6-ba06-4fde-834e-3b465d913510"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[Id = "Files", ItemKind = "Folder"]}[Data],
  #"Navigation 3" = #"Navigation 2"{[Name = "Operators.csv"]}[Content],
  #"Imported CSV" = Csv.Document(#"Navigation 3", [Delimiter = ",", Columns = 7, QuoteStyle = QuoteStyle.None]),
  #"Promoted headers" = Table.PromoteHeaders(#"Imported CSV", [PromoteAllScalars = true]),
  #"Changed column type" = Table.TransformColumnTypes(#"Promoted headers", {{"Operator id", Int64.Type}, {"first_name", type text}, {"last_name", type text}, {"email", type text}, {"gender", type text}, {"role", type text}, {"team", Int64.Type}}, "pt"),
  #"Renamed columns" = Table.RenameColumns(#"Changed column type", {{"Operator id", "OperatorID"}, {"first_name", "FirstName"}, {"last_name", "LastName"}, {"email", "Email"}, {"gender", "Gender"}, {"role", "Role"}, {"team", "Team"}}),
  #"Duplicated column" = Table.DuplicateColumn(#"Renamed columns", "OperatorID", "OperatorID - Copy"),
  #"Reordered columns" = Table.ReorderColumns(#"Duplicated column", {"OperatorID - Copy", "OperatorID", "FirstName", "LastName", "Email", "Gender", "Role", "Team"}),
  #"Renamed columns 1" = Table.RenameColumns(#"Reordered columns", {{"OperatorID - Copy", "OperatorKey"}}),
  #"Added custom" = Table.TransformColumnTypes(Table.AddColumn(#"Renamed columns 1", "Custom", each [FirstName] & " " & [LastName]), {{"Custom", type text}}),
  #"Reordered columns 1" = Table.ReorderColumns(#"Added custom", {"OperatorKey", "OperatorID", "FirstName", "LastName", "Custom", "Email", "Gender", "Role", "Team"}),
  #"Renamed columns 2" = Table.RenameColumns(#"Reordered columns 1", {{"Custom", "FullName"}, {"OperatorKey", "SK_Operator"}}),
  #"Removed columns" = Table.RemoveColumns(#"Renamed columns 2", {"OperatorID"})
in
  #"Removed columns";
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "DimLocation_DataDestination", IsNewTarget = false], Settings = [Kind = "Manual", AllowCreation = false, ColumnSettings = [Mappings = {[SourceColumnName = "SK_Location", DestinationColumnName = "SK_Location"], [SourceColumnName = "Municipality", DestinationColumnName = "Municipality"], [SourceColumnName = "District", DestinationColumnName = "District"], [SourceColumnName = "Country", DestinationColumnName = "Country"]}], DynamicSchema = false, UpdateMethod = [Kind = "Replace"], TypeSettings = [Kind = "Table"]]]}]
shared DimLocation = let
    Source = Lakehouse.Contents(null),
    Navigation = Source{[workspaceId = "b7626cf0-cc95-4e17-9611-abea9e945cb8"]}[Data],
    #"Navigation 1" = Navigation{[lakehouseId = "b90961d6-ba06-4fde-834e-3b465d913510"]}[Data],
    #"Navigation 2" = #"Navigation 1"{[Id = "Files", ItemKind = "Folder"]}[Data],

    LocationFile = #"Navigation 2"{[Name = "Locations.csv"]}[Content],
    DistrictMapFile = #"Navigation 2"{[Name = "cod_post_map_clean.csv"]}[Content],

    #"Imported Locations" =
        Csv.Document(
            LocationFile,
            [Delimiter = ",", Columns = 4, Encoding = 1252, QuoteStyle = QuoteStyle.None]
        ),

    #"Renamed location columns" =
        Table.RenameColumns(
            #"Imported Locations",
            {
                {"Column1", "LocationID"},
                {"Column2", "Municipality"},
                {"Column3", "District"},
                {"Column4", "Country"}
            }
        ),

    #"Changed location types" =
        Table.TransformColumnTypes(
            #"Renamed location columns",
            {
                {"LocationID", Int64.Type},
                {"Municipality", type text},
                {"District", type text},
                {"Country", type text}
            },
            "pt"
        ),

    #"Removed blank location rows" =
        Table.SelectRows(
            #"Changed location types",
            each [LocationID] <> null
                and [Municipality] <> null
                and Text.Trim(Text.From([Municipality])) <> ""
        ),

    #"Cleaned location text" =
        Table.TransformColumns(
            #"Removed blank location rows",
            {
                {"Municipality", each Text.Trim(Text.From(_)), type text},
                {"District", each if _ = null or Text.Trim(Text.From(_)) = "" then null else Text.Trim(Text.From(_)), type text},
                {"Country", each Text.Trim(Text.From(_)), type text}
            }
        ),

    #"Imported district map" =
        Csv.Document(
            DistrictMapFile,
            [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]
        ),

    #"Promoted map headers" =
        Table.PromoteHeaders(
            #"Imported district map",
            [PromoteAllScalars = true]
        ),

    #"Selected map columns" =
        Table.SelectColumns(
            #"Promoted map headers",
            {
                "Distrito",
                "Concelho"
            }
        ),

    #"Changed map types" =
        Table.TransformColumnTypes(
            #"Selected map columns",
            {
                {"Distrito", type text},
                {"Concelho", type text}
            },
            "pt"
        ),

    #"Cleaned map text" =
        Table.TransformColumns(
            #"Changed map types",
            {
                {"Distrito", each Text.Trim(Text.From(_)), type text},
                {"Concelho", each Text.Trim(Text.From(_)), type text}
            }
        ),

    #"Removed duplicate map rows" =
        Table.Distinct(
            #"Cleaned map text",
            {
                "Distrito",
                "Concelho"
            }
        ),

    #"Grouped district map" =
        Table.Group(
            #"Removed duplicate map rows",
            {"Concelho"},
            {
                {"DistrictList", each List.Distinct([Distrito]), type list}
            }
        ),

    #"Added unique district from map" =
        Table.AddColumn(
            #"Grouped district map",
            "DistrictFromMap",
            each if List.Count([DistrictList]) = 1 then [DistrictList]{0} else null,
            type text
        ),

    #"Prepared map for join" =
        Table.SelectColumns(
            #"Added unique district from map",
            {
                "Concelho",
                "DistrictFromMap"
            }
        ),

    #"Merged with district map" =
        Table.NestedJoin(
            #"Cleaned location text",
            {"Municipality"},
            #"Prepared map for join",
            {"Concelho"},
            "DistrictLookup",
            JoinKind.LeftOuter
        ),

    #"Expanded district map" =
        Table.ExpandTableColumn(
            #"Merged with district map",
            "DistrictLookup",
            {"DistrictFromMap"},
            {"DistrictFromMap"}
        ),

    ManualDistrict = (locationName as nullable text) as nullable text =>
        let
            name = if locationName = null then "" else Text.Trim(Text.From(locationName)),
            result =
                if name = "Angeja" then "Aveiro"
                else if name = "Freguesia de São Pedro do Sul" then "Viseu"
                else if name = "Malveira da Serra" then "Lisboa"
                else if name = "Pardilhó" then "Aveiro"
                else if name = "Quarteira" then "Faro"
                else if name = "São João de Madeira" then "Aveiro"
                else if name = "Sobral da Adiça" then "Beja"
                else if name = "Vimeiro" then "Leiria"
                else "Unknown"
        in
            result,

    #"Added final district" =
        Table.AddColumn(
            #"Expanded district map",
            "FinalDistrict",
            each
                if [District] <> null and Text.Trim(Text.From([District])) <> "" then [District]
                else if [DistrictFromMap] <> null and Text.Trim(Text.From([DistrictFromMap])) <> "" then [DistrictFromMap]
                else ManualDistrict([Municipality]),
            type text
        ),

    #"Removed old district columns" =
        Table.RemoveColumns(
            #"Added final district",
            {
                "District",
                "DistrictFromMap"
            }
        ),

    #"Renamed final district" =
        Table.RenameColumns(
            #"Removed old district columns",
            {
                {"FinalDistrict", "District"}
            }
        ),

    #"Added SK_Location" =
        Table.DuplicateColumn(
            #"Renamed final district",
            "LocationID",
            "SK_Location"
        ),

    #"Changed key type" =
        Table.TransformColumnTypes(
            #"Added SK_Location",
            {
                {"SK_Location", Int64.Type}
            },
            "pt"
        ),

    #"Reordered columns" =
        Table.ReorderColumns(
            #"Changed key type",
            {
                "SK_Location",
                "LocationID",
                "Municipality",
                "District",
                "Country"
            }
        ),
  #"Sorted rows" = Table.Sort(#"Reordered columns", {{"SK_Location", Order.Descending}}),
  #"Removed columns" = Table.RemoveColumns(#"Sorted rows", {"LocationID"})
in
    #"Removed columns";
shared #"Pharmacies A csv" = let
  Source = Lakehouse.Contents(null),
  Navigation = Source{[workspaceId = "b7626cf0-cc95-4e17-9611-abea9e945cb8"]}[Data],
  #"Navigation 1" = Navigation{[lakehouseId = "b90961d6-ba06-4fde-834e-3b465d913510"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[Id = "Files", ItemKind = "Folder"]}[Data],
  #"Navigation 3" = #"Navigation 2"{[Name = "Pharmacies A.csv"]}[Content],
  #"Imported CSV" = Csv.Document(#"Navigation 3", [Delimiter = ",", Columns = 3, QuoteStyle = QuoteStyle.None])
in
  #"Imported CSV";
shared #"Pharmacies B csv" = let
  Source = Lakehouse.Contents(null),
  Navigation = Source{[workspaceId = "b7626cf0-cc95-4e17-9611-abea9e945cb8"]}[Data],
  #"Navigation 1" = Navigation{[lakehouseId = "b90961d6-ba06-4fde-834e-3b465d913510"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[Id = "Files", ItemKind = "Folder"]}[Data],
  #"Navigation 3" = #"Navigation 2"{[Name = "Pharmacies B.csv"]}[Content],
  #"Imported CSV" = Csv.Document(#"Navigation 3", [Delimiter = ",", Columns = 3, QuoteStyle = QuoteStyle.None])
in
  #"Imported CSV";
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "DimPharmacy_DataDestination", IsNewTarget = false], Settings = [Kind = "Manual", AllowCreation = false, ColumnSettings = [Mappings = {[SourceColumnName = "SK_Pharmacy", DestinationColumnName = "SK_Pharmacy"], [SourceColumnName = "PharmacyName", DestinationColumnName = "PharmacyName"], [SourceColumnName = "FK_Location", DestinationColumnName = "FK_Location"]}], DynamicSchema = false, UpdateMethod = [Kind = "Replace"], TypeSettings = [Kind = "Table"]]]}]
shared DimPharmacy = let
    Source = Lakehouse.Contents(null),
    Navigation = Source{[workspaceId = "b7626cf0-cc95-4e17-9611-abea9e945cb8"]}[Data],
    #"Navigation 1" = Navigation{[lakehouseId = "b90961d6-ba06-4fde-834e-3b465d913510"]}[Data],
    #"Navigation 2" = #"Navigation 1"{[Id = "Files", ItemKind = "Folder"]}[Data],

    PharmacyAFile = #"Navigation 2"{[Name = "Pharmacies A.csv"]}[Content],
    PharmacyBFile = #"Navigation 2"{[Name = "Pharmacies B.csv"]}[Content],

    PharmacyA =
        Csv.Document(
            PharmacyAFile,
            [Delimiter = ",", Columns = 3, Encoding = 1252, QuoteStyle = QuoteStyle.None]
        ),

    PharmacyB =
        Csv.Document(
            PharmacyBFile,
            [Delimiter = ",", Columns = 3, Encoding = 1252, QuoteStyle = QuoteStyle.None]
        ),

    #"Promoted headers A" =
        Table.PromoteHeaders(
            PharmacyA,
            [PromoteAllScalars = true]
        ),

    #"Promoted headers B" =
        Table.PromoteHeaders(
            PharmacyB,
            [PromoteAllScalars = true]
        ),

    #"Appended pharmacies" =
        Table.Combine(
            {
                #"Promoted headers A",
                #"Promoted headers B"
            }
        ),

    #"Renamed columns" =
        Table.RenameColumns(
            #"Appended pharmacies",
            {
                {"Pharmacy ID", "PharmacyID"},
                {"Nome da farmácia", "PharmacyName"},
                {"Localização", "LocationID"}
            }
        ),

    #"Changed column type" =
        Table.TransformColumnTypes(
            #"Renamed columns",
            {
                {"PharmacyID", Int64.Type},
                {"PharmacyName", type text},
                {"LocationID", Int64.Type}
            },
            "pt"
        ),

    #"Removed blank rows" =
        Table.SelectRows(
            #"Changed column type",
            each [PharmacyID] <> null
                and [PharmacyName] <> null
                and Text.Trim(Text.From([PharmacyName])) <> ""
        ),

    #"Removed duplicates" =
        Table.Distinct(
            #"Removed blank rows",
            {"PharmacyID"}
        ),

    #"Cleaned text" =
        Table.TransformColumns(
            #"Removed duplicates",
            {
                {"PharmacyName", each Text.Trim(Text.From(_)), type text}
            }
        ),

    #"Duplicated PharmacyID" =
        Table.DuplicateColumn(
            #"Cleaned text",
            "PharmacyID",
            "PharmacyKey"
        ),

    #"Changed key type" =
        Table.TransformColumnTypes(
            #"Duplicated PharmacyID",
            {
                {"PharmacyKey", Int64.Type}
            },
            "pt"
        ),

    #"Reordered columns" =
        Table.ReorderColumns(
            #"Changed key type",
            {
                "PharmacyKey",
                "PharmacyID",
                "PharmacyName",
                "LocationID"
            }
        ),
  #"Renamed columns 1" = Table.RenameColumns(#"Reordered columns", {{"PharmacyKey", "SK_Pharmacy"}, {"LocationID", "FK_Location"}}),
  #"Removed columns" = Table.RemoveColumns(#"Renamed columns 1", {"PharmacyID"})
in
    #"Removed columns";
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "DimProduct_DataDestination", IsNewTarget = false], Settings = [Kind = "Manual", AllowCreation = false, ColumnSettings = [Mappings = {[SourceColumnName = "SK_Product", DestinationColumnName = "SK_Product"], [SourceColumnName = "CNP", DestinationColumnName = "CNP"], [SourceColumnName = "ProductName", DestinationColumnName = "ProductName"], [SourceColumnName = "Manufacturer", DestinationColumnName = "Manufacturer"], [SourceColumnName = "Brand", DestinationColumnName = "Brand"], [SourceColumnName = "ProductPresentation", DestinationColumnName = "ProductPresentation"], [SourceColumnName = "IsGeneric", DestinationColumnName = "IsGeneric"], [SourceColumnName = "GenericLabel", DestinationColumnName = "GenericLabel"]}], DynamicSchema = false, UpdateMethod = [Kind = "Replace"], TypeSettings = [Kind = "Table"]]]}]
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
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "DimDate_DataDestination", IsNewTarget = false], Settings = [Kind = "Manual", AllowCreation = false, ColumnSettings = [Mappings = {[SourceColumnName = "SK_Date", DestinationColumnName = "SK_Date"], [SourceColumnName = "FullDate", DestinationColumnName = "FullDate"], [SourceColumnName = "Day", DestinationColumnName = "Day"], [SourceColumnName = "DayName", DestinationColumnName = "DayName"], [SourceColumnName = "WeekNumber", DestinationColumnName = "WeekNumber"], [SourceColumnName = "Month", DestinationColumnName = "Month"], [SourceColumnName = "MonthName", DestinationColumnName = "MonthName"], [SourceColumnName = "Quarter", DestinationColumnName = "Quarter"], [SourceColumnName = "QuarterName", DestinationColumnName = "QuarterName"], [SourceColumnName = "Year", DestinationColumnName = "Year"], [SourceColumnName = "IsWeekend", DestinationColumnName = "IsWeekend"], [SourceColumnName = "IsHoliday", DestinationColumnName = "IsHoliday"], [SourceColumnName = "YTDFlag", DestinationColumnName = "YTDFlag"]}], DynamicSchema = false, UpdateMethod = [Kind = "Replace"], TypeSettings = [Kind = "Table"]]]}]
shared DimDate = let
    StartDate = #date(2020, 1, 1),
    EndDate = #date(2023, 6, 2),

    EndDateDayOfYear =
        Duration.Days(EndDate - Date.StartOfYear(EndDate)) + 1,

    HolidayList =
        {
            // Portugal national holidays - 2020
            #date(2020, 1, 1),
            #date(2020, 4, 10),
            #date(2020, 4, 12),
            #date(2020, 4, 25),
            #date(2020, 5, 1),
            #date(2020, 6, 10),
            #date(2020, 6, 11),
            #date(2020, 8, 15),
            #date(2020, 10, 5),
            #date(2020, 11, 1),
            #date(2020, 12, 1),
            #date(2020, 12, 8),
            #date(2020, 12, 25),

            // Portugal national holidays - 2021
            #date(2021, 1, 1),
            #date(2021, 4, 2),
            #date(2021, 4, 4),
            #date(2021, 4, 25),
            #date(2021, 5, 1),
            #date(2021, 6, 3),
            #date(2021, 6, 10),
            #date(2021, 8, 15),
            #date(2021, 10, 5),
            #date(2021, 11, 1),
            #date(2021, 12, 1),
            #date(2021, 12, 8),
            #date(2021, 12, 25),

            // Portugal national holidays - 2022
            #date(2022, 1, 1),
            #date(2022, 4, 15),
            #date(2022, 4, 17),
            #date(2022, 4, 25),
            #date(2022, 5, 1),
            #date(2022, 6, 10),
            #date(2022, 6, 16),
            #date(2022, 8, 15),
            #date(2022, 10, 5),
            #date(2022, 11, 1),
            #date(2022, 12, 1),
            #date(2022, 12, 8),
            #date(2022, 12, 25),

            // Portugal national holidays - 2023
            #date(2023, 1, 1),
            #date(2023, 4, 7),
            #date(2023, 4, 9),
            #date(2023, 4, 25),
            #date(2023, 5, 1),
            #date(2023, 6, 8),
            #date(2023, 6, 10),
            #date(2023, 8, 15),
            #date(2023, 10, 5),
            #date(2023, 11, 1),
            #date(2023, 12, 1),
            #date(2023, 12, 8),
            #date(2023, 12, 25)
        },

    DateList =
        List.Dates(
            StartDate,
            Duration.Days(EndDate - StartDate) + 1,
            #duration(1, 0, 0, 0)
        ),

    DateTable =
        Table.FromList(
            DateList,
            Splitter.SplitByNothing(),
            {"FullDate"}
        ),

    #"Changed FullDate type" =
        Table.TransformColumnTypes(
            DateTable,
            {{"FullDate", type date}},
            "pt"
        ),

    #"Added DateKey" =
        Table.AddColumn(
            #"Changed FullDate type",
            "DateKey",
            each Date.Year([FullDate]) * 10000 + Date.Month([FullDate]) * 100 + Date.Day([FullDate]),
            Int64.Type
        ),

    #"Added Day" =
        Table.AddColumn(
            #"Added DateKey",
            "Day",
            each Date.Day([FullDate]),
            Int64.Type
        ),

    #"Added DayName" =
        Table.AddColumn(
            #"Added Day",
            "DayName",
            each Date.DayOfWeekName([FullDate], "en-US"),
            type text
        ),

    #"Added WeekNumber" =
        Table.AddColumn(
            #"Added DayName",
            "WeekNumber",
            each Date.WeekOfYear([FullDate]),
            Int64.Type
        ),

    #"Added Month" =
        Table.AddColumn(
            #"Added WeekNumber",
            "Month",
            each Date.Month([FullDate]),
            Int64.Type
        ),

    #"Added MonthName" =
        Table.AddColumn(
            #"Added Month",
            "MonthName",
            each Date.MonthName([FullDate], "en-US"),
            type text
        ),

    #"Added Quarter" =
        Table.AddColumn(
            #"Added MonthName",
            "Quarter",
            each Date.QuarterOfYear([FullDate]),
            Int64.Type
        ),

    #"Added QuarterName" =
        Table.AddColumn(
            #"Added Quarter",
            "QuarterName",
            each "Q" & Text.From(Date.QuarterOfYear([FullDate])),
            type text
        ),

    #"Added Year" =
        Table.AddColumn(
            #"Added QuarterName",
            "Year",
            each Date.Year([FullDate]),
            Int64.Type
        ),

    #"Added IsWeekend" =
        Table.AddColumn(
            #"Added Year",
            "IsWeekend",
            each Date.DayOfWeek([FullDate], Day.Monday) >= 5,
            type logical
        ),

    #"Added IsHoliday" =
        Table.AddColumn(
            #"Added IsWeekend",
            "IsHoliday",
            each List.Contains(HolidayList, [FullDate]),
            type logical
        ),

    #"Added YTDFlag" =
        Table.AddColumn(
            #"Added IsHoliday",
            "YTDFlag",
            each Duration.Days([FullDate] - Date.StartOfYear([FullDate])) + 1 <= EndDateDayOfYear,
            type logical
        ),

    #"Reordered columns" =
        Table.ReorderColumns(
            #"Added YTDFlag",
            {
                "DateKey",
                "FullDate",
                "Day",
                "DayName",
                "WeekNumber",
                "Month",
                "MonthName",
                "Quarter",
                "QuarterName",
                "Year",
                "IsWeekend",
                "IsHoliday",
                "YTDFlag"
            }
        ),
  #"Renamed columns" = Table.RenameColumns(#"Reordered columns", {{"DateKey", "SK_Date"}})
in
    #"Renamed columns";
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "DimTime_DataDestination", IsNewTarget = false], Settings = [Kind = "Manual", AllowCreation = false, ColumnSettings = [Mappings = {[SourceColumnName = "SK_Time", DestinationColumnName = "SK_Time"], [SourceColumnName = "Hour", DestinationColumnName = "Hour"], [SourceColumnName = "Minute", DestinationColumnName = "Minute"], [SourceColumnName = "TimeLabel", DestinationColumnName = "TimeLabel"], [SourceColumnName = "DayPeriod", DestinationColumnName = "DayPeriod"]}], DynamicSchema = false, UpdateMethod = [Kind = "Replace"], TypeSettings = [Kind = "Table"]]]}]
shared DimTime = let
    TimeList =
        List.Times(
            #time(0, 0, 0),
            24 * 60,
            #duration(0, 0, 1, 0)
        ),

    TimeTable =
        Table.FromList(
            TimeList,
            Splitter.SplitByNothing(),
            {"FullTime"}
        ),

    #"Changed FullTime type" =
        Table.TransformColumnTypes(
            TimeTable,
            {{"FullTime", type time}},
            "pt"
        ),

    #"Added SK_Time" =
        Table.AddColumn(
            #"Changed FullTime type",
            "SK_Time",
            each Time.Hour([FullTime]) * 100 + Time.Minute([FullTime]),
            Int64.Type
        ),

    #"Added Hour" =
        Table.AddColumn(
            #"Added SK_Time",
            "Hour",
            each Time.Hour([FullTime]),
            Int64.Type
        ),

    #"Added Minute" =
        Table.AddColumn(
            #"Added Hour",
            "Minute",
            each Time.Minute([FullTime]),
            Int64.Type
        ),

    #"Added TimeLabel" =
        Table.AddColumn(
            #"Added Minute",
            "TimeLabel",
            each
                Text.PadStart(Text.From(Time.Hour([FullTime])), 2, "0")
                & ":"
                & Text.PadStart(Text.From(Time.Minute([FullTime])), 2, "0"),
            type text
        ),

    #"Added DayPeriod" =
        Table.AddColumn(
            #"Added TimeLabel",
            "DayPeriod",
            each
                if Time.Hour([FullTime]) < 6 then "Night"
                else if Time.Hour([FullTime]) < 12 then "Morning"
                else if Time.Hour([FullTime]) < 18 then "Afternoon"
                else "Evening",
            type text
        ),

    #"Removed FullTime" =
        Table.RemoveColumns(
            #"Added DayPeriod",
            {"FullTime"}
        ),

    #"Reordered columns" =
        Table.ReorderColumns(
            #"Removed FullTime",
            {
                "SK_Time",
                "Hour",
                "Minute",
                "TimeLabel",
                "DayPeriod"
            }
        )
in
    #"Reordered columns";
shared DimProduct_DataDestination = let
  Pattern = Fabric.Warehouse([CreateNavigationProperties = false, HierarchicalNavigation = true]),
  Navigation_1 = Pattern{[workspaceId = "b7626cf0-cc95-4e17-9611-abea9e945cb8"]}[Data],
  Navigation_2 = Navigation_1{[warehouseId = "31a736e4-406e-4dbb-8ee0-2354785b3f85"]}[Data],
  Navigation_3 = Navigation_2{[Schema = "dwh"]}[Data],
  TableNavigation = Navigation_3{[Name = "DimProduct"]}[Data]
in
  TableNavigation;
shared DimTime_DataDestination = let
  Pattern = Fabric.Warehouse([CreateNavigationProperties = false, HierarchicalNavigation = true]),
  Navigation_1 = Pattern{[workspaceId = "b7626cf0-cc95-4e17-9611-abea9e945cb8"]}[Data],
  Navigation_2 = Navigation_1{[warehouseId = "31a736e4-406e-4dbb-8ee0-2354785b3f85"]}[Data],
  Navigation_3 = Navigation_2{[Schema = "dwh"]}[Data],
  TableNavigation = Navigation_3{[Name = "DimTime"]}[Data]
in
  TableNavigation;
shared DimDate_DataDestination = let
  Pattern = Fabric.Warehouse([CreateNavigationProperties = false, HierarchicalNavigation = true]),
  Navigation_1 = Pattern{[workspaceId = "b7626cf0-cc95-4e17-9611-abea9e945cb8"]}[Data],
  Navigation_2 = Navigation_1{[warehouseId = "31a736e4-406e-4dbb-8ee0-2354785b3f85"]}[Data],
  Navigation_3 = Navigation_2{[Schema = "dwh"]}[Data],
  TableNavigation = Navigation_3{[Name = "DimDate"]}[Data]
in
  TableNavigation;
shared DimPOS_DataDestination = let
  Pattern = Fabric.Warehouse([CreateNavigationProperties = false, HierarchicalNavigation = true]),
  Navigation_1 = Pattern{[workspaceId = "b7626cf0-cc95-4e17-9611-abea9e945cb8"]}[Data],
  Navigation_2 = Navigation_1{[warehouseId = "31a736e4-406e-4dbb-8ee0-2354785b3f85"]}[Data],
  Navigation_3 = Navigation_2{[Schema = "dwh"]}[Data],
  TableNavigation = Navigation_3{[Name = "DimPOS"]}[Data]
in
  TableNavigation;
shared DimOperator_DataDestination = let
  Pattern = Fabric.Warehouse([CreateNavigationProperties = false, HierarchicalNavigation = true]),
  Navigation_1 = Pattern{[workspaceId = "b7626cf0-cc95-4e17-9611-abea9e945cb8"]}[Data],
  Navigation_2 = Navigation_1{[warehouseId = "31a736e4-406e-4dbb-8ee0-2354785b3f85"]}[Data],
  Navigation_3 = Navigation_2{[Schema = "dwh"]}[Data],
  TableNavigation = Navigation_3{[Name = "DimOperator"]}[Data]
in
  TableNavigation;
shared DimLocation_DataDestination = let
  Pattern = Fabric.Warehouse([CreateNavigationProperties = false, HierarchicalNavigation = true]),
  Navigation_1 = Pattern{[workspaceId = "b7626cf0-cc95-4e17-9611-abea9e945cb8"]}[Data],
  Navigation_2 = Navigation_1{[warehouseId = "31a736e4-406e-4dbb-8ee0-2354785b3f85"]}[Data],
  Navigation_3 = Navigation_2{[Schema = "dwh"]}[Data],
  TableNavigation = Navigation_3{[Name = "DimLocation"]}[Data]
in
  TableNavigation;
shared DimPharmacy_DataDestination = let
  Pattern = Fabric.Warehouse([CreateNavigationProperties = false, HierarchicalNavigation = true]),
  Navigation_1 = Pattern{[workspaceId = "b7626cf0-cc95-4e17-9611-abea9e945cb8"]}[Data],
  Navigation_2 = Navigation_1{[warehouseId = "31a736e4-406e-4dbb-8ee0-2354785b3f85"]}[Data],
  Navigation_3 = Navigation_2{[Schema = "dwh"]}[Data],
  TableNavigation = Navigation_3{[Name = "DimPharmacy"]}[Data]
in
  TableNavigation;

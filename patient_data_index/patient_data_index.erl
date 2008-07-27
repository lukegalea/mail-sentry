-module(patient_data_index).
-export([scan/1, start/0]).
-record( patient, { first_name, last_name, mrn, healthcard } ).

%% Finds patient data in content
scan(Content) ->
    Content.

start() ->
    Patients = parse_patients(),
    [FirstPatient|_] = Patients,
    io:format("Loaded ~w patients\nExample: ~p\n", [length(Patients), FirstPatient]).

patient([Mrn, LastName, FirstName, Healthcard]) ->
    #patient{ mrn = Mrn, last_name = LastName, 
	 first_name = FirstName, healthcard = Healthcard };
patient(NonMatchingRow) ->
    NonMatchingRow.

patients() ->
    [ X || X <- lists:map( fun(Patient) -> patient(Patient) end,
	       parse_patients() ), is_record(X, patient) ].

parse_patients() ->
    csv:parse_csv(patients_data()).

patients_data() ->
    {ok, Bin} = file:read_file("../data/medimail_dev.csv"),
    strip_eof(binary_to_list(Bin)).

strip_eof(L) ->
    [_|Remainder] = lists:reverse(L),
    lists:reverse(Remainder).

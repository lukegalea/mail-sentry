-module(csv).
-export([parse_csv/1, parse_tab_delimited/1, tokenize/2, parse/3]).

tokenize(Content, Delimiters) ->
    tokenize(Content, [], [], Delimiters).

tokenize([], Tokens, Token, _) ->
    [Token|Tokens];
tokenize([H|T], Tokens, Token, Delimiters) ->
    case lists:member(H, Delimiters) of
	true ->
	    found_token(T, Tokens, Token, Delimiters);
	false -> 
	    tokenize(T, Tokens, [H|Token], Delimiters)
    end.

found_token(T, Tokens, Token, Delimiters) ->
    case Token =:= [] of
	true ->
	    tokenize(T, Tokens, [], Delimiters);
	false ->
	    tokenize(T, [Token|Tokens], [], Delimiters)
    end.

parse_tab_delimited( Content ) ->
    parse(Content, [$\n], [$\t,$\"]).

parse_csv( Content ) ->
    parse(Content, [$\n], [$,,$\"]).

parse( Content, LineDelimiters, FieldDelimiters ) ->
    lists:map( fun(Row) -> tokenize(Row, FieldDelimiters) end, 
	       tokenize(Content, LineDelimiters) ).

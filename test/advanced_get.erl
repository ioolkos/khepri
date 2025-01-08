%% This Source Code Form is subject to the terms of the Mozilla Public
%% License, v. 2.0. If a copy of the MPL was not distributed with this
%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%
%% Copyright © 2021-2025 Broadcom. All Rights Reserved. The term "Broadcom"
%% refers to Broadcom Inc. and/or its subsidiaries.
%%

-module(advanced_get).

-include_lib("eunit/include/eunit.hrl").

-include_lib("horus/include/horus.hrl").

-include("include/khepri.hrl").
-include("src/khepri_error.hrl").
-include("test/helpers.hrl").

get_non_existing_node_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [?_assertEqual(
         {error, ?khepri_error(node_not_found, #{node_name => foo,
                                                 node_path => [foo],
                                                 node_is_target => true})},
         khepri_adv:get(?FUNCTION_NAME, [foo]))]}.

get_existing_node_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [?_assertEqual(
         {ok, #{[foo] => #{payload_version => 1}}},
         khepri_adv:create(?FUNCTION_NAME, [foo], foo_value)),
      ?_assertEqual(
         {ok, #{[foo] => #{data => foo_value,
                           payload_version => 1}}},
         khepri_adv:get(?FUNCTION_NAME, [foo]))]}.

get_existing_node_with_sproc_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [?_assertEqual(
         {ok, #{[foo] => #{payload_version => 1}}},
         khepri_adv:create(?FUNCTION_NAME, [foo], fun() -> ok end)),
      ?_assertMatch(
         {ok, #{[foo] := #{sproc := Fun,
                           payload_version := 1}}}
           when ?IS_HORUS_STANDALONE_FUN(Fun),
         khepri_adv:get(?FUNCTION_NAME, [foo]))]}.

get_existing_node_with_no_payload_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [?_assertEqual(
         {ok, #{[foo, bar] => #{payload_version => 1}}},
         khepri_adv:create(?FUNCTION_NAME, [foo, bar], bar_value)),
      ?_assertEqual(
         {ok, #{[foo] => #{payload_version => 1}}},
         khepri_adv:get(?FUNCTION_NAME, [foo]))]}.

invalid_get_call_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [?_assertError(
         ?khepri_exception(
            possibly_matching_many_nodes_denied,
            #{path := _}),
         khepri_adv:get(?FUNCTION_NAME, [?KHEPRI_WILDCARD_STAR]))]}.

get_many_non_existing_nodes_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [?_assertEqual(
         {ok, #{}},
         khepri_adv:get_many(?FUNCTION_NAME, [?KHEPRI_WILDCARD_STAR]))]}.

get_many_existing_nodes_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [?_assertEqual(
         {ok, #{[foo, bar] => #{payload_version => 1}}},
         khepri_adv:create(?FUNCTION_NAME, [foo, bar], bar_value)),
      ?_assertEqual(
         {ok, #{[baz] => #{payload_version => 1}}},
         khepri_adv:create(?FUNCTION_NAME, [baz], baz_value)),
      ?_assertEqual(
         {ok, #{[foo] => #{payload_version => 1},
                [baz] => #{data => baz_value,
                           payload_version => 1}}},
         khepri_adv:get_many(?FUNCTION_NAME, [?KHEPRI_WILDCARD_STAR])),
      ?_assertError(
         ?khepri_exception(
            possibly_matching_many_nodes_denied,
            #{path := [?KHEPRI_WILDCARD_STAR]}),
         khepri_adv:get_many(
           ?FUNCTION_NAME, [?KHEPRI_WILDCARD_STAR],
           #{expect_specific_node => true}))]}.

%% This Source Code Form is subject to the terms of the Mozilla Public
%% License, v. 2.0. If a copy of the MPL was not distributed with this
%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%
%% Copyright © 2021-2022 VMware, Inc. or its affiliates.  All rights reserved.
%%

-module(simple_get).

-include_lib("eunit/include/eunit.hrl").

-include("include/khepri.hrl").
-include("src/internal.hrl").
-include("src/khepri_fun.hrl").
-include("test/helpers.hrl").

get_non_existing_node_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [?_assertEqual(
         {error, {node_not_found, #{node_name => foo,
                                    node_path => [foo],
                                    node_is_target => true}}},
         khepri:get(?FUNCTION_NAME, [foo]))]}.

get_existing_node_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [?_assertEqual(
         ok,
         khepri:create(?FUNCTION_NAME, [foo], foo_value)),
      ?_assertEqual(
         {ok, foo_value},
         khepri:get(?FUNCTION_NAME, [foo]))]}.

get_existing_node_with_sproc_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [?_assertEqual(
         ok,
         khepri:create(?FUNCTION_NAME, [foo], fun() -> ok end)),
      ?_assertMatch(
         {ok, #standalone_fun{}},
         khepri:get(?FUNCTION_NAME, [foo]))]}.

get_existing_node_with_no_payload_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [?_assertEqual(
         ok,
         khepri:create(?FUNCTION_NAME, [foo, bar], bar_value)),
      ?_assertEqual(
         {ok, undefined},
         khepri:get(?FUNCTION_NAME, [foo]))]}.

invalid_get_call_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [?_assertError(
         {khepri,
          invalid_call,
          "Invalid use of khepri_adv:get/3:\n"
          "Called with a path pattern which could match many nodes:\n"
          "[{if_name_matches,any,undefined}]"},
         khepri:get(?FUNCTION_NAME, [?STAR]))]}.

get_or_default_non_existing_node_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [?_assertEqual(
         {ok, default},
         khepri:get_or(?FUNCTION_NAME, [foo], default))]}.

get_or_default_on_existing_node_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [?_assertEqual(
         ok,
         khepri:create(?FUNCTION_NAME, [foo], foo_value)),
      ?_assertEqual(
         {ok, foo_value},
         khepri:get_or(?FUNCTION_NAME, [foo], default))]}.

get_or_default_on_existing_node_with_no_payload_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [?_assertEqual(
         ok,
         khepri:create(?FUNCTION_NAME, [foo, bar], bar_value)),
      ?_assertEqual(
         {ok, default},
         khepri:get_or(?FUNCTION_NAME, [foo], default))]}.

invalid_get_or_call_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [?_assertError(
         {khepri,
          invalid_call,
          "Invalid use of khepri_adv:get/3:\n"
          "Called with a path pattern which could match many nodes:\n"
          "[{if_name_matches,any,undefined}]"},
         khepri:get_or(?FUNCTION_NAME, [?STAR], default))]}.

get_many_non_existing_nodes_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [?_assertEqual(
         {ok, #{}},
         khepri:get_many(?FUNCTION_NAME, [?STAR]))]}.

get_many_existing_nodes_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [?_assertEqual(
         ok,
         khepri:create(?FUNCTION_NAME, [foo, bar], bar_value)),
      ?_assertEqual(
         ok,
         khepri:create(?FUNCTION_NAME, [baz], baz_value)),
      ?_assertEqual(
         {ok, #{[foo] => undefined,
                [baz] => baz_value}},
         khepri:get_many(?FUNCTION_NAME, [?STAR])),
      ?_assertEqual(
         {error,
          {possibly_matching_many_nodes_denied,
           [?STAR]}},
         khepri:get_many(
           ?FUNCTION_NAME, [?STAR],
           #{expect_specific_node => true}))]}.

get_many_or_default_non_existing_nodes_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [?_assertEqual(
         {ok, #{}},
         khepri:get_many_or(
           ?FUNCTION_NAME, [?STAR], default))]}.

get_many_or_default_existing_nodes_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [?_assertEqual(
         ok,
         khepri:create(?FUNCTION_NAME, [foo, bar], bar_value)),
      ?_assertEqual(
         ok,
         khepri:create(?FUNCTION_NAME, [baz], baz_value)),
      ?_assertEqual(
         {ok, #{[foo] => default,
                [baz] => baz_value}},
         khepri:get_many_or(
           ?FUNCTION_NAME, [?STAR], default)),
      ?_assertEqual(
         {error,
          {possibly_matching_many_nodes_denied,
           [?STAR]}},
         khepri:get_many_or(
           ?FUNCTION_NAME, [?STAR], default,
           #{expect_specific_node => true}))]}.

check_node_exists_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [?_assertEqual(
         ok,
         khepri:create(?FUNCTION_NAME, [foo, bar], bar_value)),
      ?_assert(khepri:exists(?FUNCTION_NAME, [foo])),
      ?_assert(khepri:exists(?FUNCTION_NAME, [foo, bar])),
      ?_assertNot(khepri:exists(?FUNCTION_NAME, [baz]))]}.

check_invalid_exists_call_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [?_assertError(
         {khepri,
          invalid_call,
          "Invalid use of khepri:exists/3:\n"
          "Called with a path pattern which could match many nodes:\n"
          "[{if_name_matches,any,undefined}]"},
         khepri:exists(?FUNCTION_NAME, [?STAR]))]}.

check_node_has_data_on_non_existing_node_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [?_assertNot(khepri:has_data(?FUNCTION_NAME, [foo]))]}.

check_node_has_data_on_existing_node_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [?_assertEqual(
         ok,
         khepri:create(?FUNCTION_NAME, [foo, bar], bar_value)),
      ?_assertEqual(
         ok,
         khepri:create(?FUNCTION_NAME, [baz], baz_value)),
      ?_assertNot(khepri:has_data(?FUNCTION_NAME, [foo])),
      ?_assert(khepri:has_data(?FUNCTION_NAME, [foo, bar])),
      ?_assert(khepri:has_data(?FUNCTION_NAME, [baz]))]}.

check_invalid_has_data_call_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [?_assertError(
         {khepri,
          invalid_call,
          "Invalid use of khepri:has_data/3:\n"
          "Called with a path pattern which could match many nodes:\n"
          "[{if_name_matches,any,undefined}]"},
         khepri:has_data(?FUNCTION_NAME, [?STAR]))]}.

check_node_is_sproc_on_non_existing_node_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [?_assertNot(khepri:is_sproc(?FUNCTION_NAME, [foo]))]}.

check_node_is_sproc_on_existing_node_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [?_assertEqual(
         ok,
         khepri:create(?FUNCTION_NAME, [foo, bar], fun() -> bar_value end)),
      ?_assertEqual(
         ok,
         khepri:create(?FUNCTION_NAME, [baz], fun() -> baz_value end)),
      ?_assertNot(khepri:is_sproc(?FUNCTION_NAME, [foo])),
      ?_assert(khepri:is_sproc(?FUNCTION_NAME, [foo, bar])),
      ?_assert(khepri:is_sproc(?FUNCTION_NAME, [baz]))]}.

check_invalid_is_sproc_call_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [?_assertError(
         {khepri,
          invalid_call,
          "Invalid use of khepri:is_sproc/3:\n"
          "Called with a path pattern which could match many nodes:\n"
          "[{if_name_matches,any,undefined}]"},
         khepri:is_sproc(?FUNCTION_NAME, [?STAR]))]}.

count_non_existing_node_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [?_assertEqual(
         {ok, 0},
         khepri:count(?FUNCTION_NAME, [foo])),
      ?_assertEqual(
         {ok, 0},
         khepri:count(
           ?FUNCTION_NAME, [foo], #{expect_specific_node => true}))]}.

count_existing_node_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [?_assertEqual(
         ok,
         khepri:create(?FUNCTION_NAME, [foo], foo_value)),
      ?_assertEqual(
         {ok, 1},
         khepri:count(?FUNCTION_NAME, [foo]))]}.

count_many_nodes_test_() ->
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [?_assertEqual(
         ok,
         khepri:create(?FUNCTION_NAME, [foo, bar], bar_value)),
      ?_assertEqual(
         ok,
         khepri:create(?FUNCTION_NAME, [baz], baz_value)),

      ?_assertEqual(
         {ok, 2},
         khepri:count(?FUNCTION_NAME, [?THIS_NODE, ?STAR])),
      ?_assertEqual(
         {ok, 3},
         khepri:count(?FUNCTION_NAME, [?STAR_STAR])),
      ?_assertEqual(
         {error,
          {possibly_matching_many_nodes_denied,
           [?STAR]}},
         khepri:count(
           ?FUNCTION_NAME,
           [?THIS_NODE, ?STAR],
           #{expect_specific_node => true}))]}.

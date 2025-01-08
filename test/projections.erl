%% This Source Code Form is subject to the terms of the Mozilla Public
%% License, v. 2.0. If a copy of the MPL was not distributed with this
%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%
%% Copyright © 2022-2025 Broadcom. All Rights Reserved. The term "Broadcom"
%% refers to Broadcom Inc. and/or its subsidiaries.
%%

-module(projections).

-include_lib("eunit/include/eunit.hrl").

-include("include/khepri.hrl").
-include("src/khepri_machine.hrl").
-include("src/khepri_error.hrl").
-include("test/helpers.hrl").

-dialyzer({nowarn_function, [unknown_options_are_rejected_test/0]}).

trigger_simple_projection_on_path_test_() ->
    ProjectFun = fun(Path, Payload) -> {Path, Payload} end,
    PathPattern = [stock, wood, <<"oak">>],
    Data = 100,
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [{inorder,
        [{"Register the projection",
          ?_test(
              begin
                  Projection = khepri_projection:new(?MODULE, ProjectFun),
                  ?assertEqual(
                    ok,
                    khepri:register_projection(
                      ?FUNCTION_NAME, PathPattern, Projection))
              end)},

         {"The store contains the projection",
          ?_assertEqual(
            true,
            khepri:has_projection(?FUNCTION_NAME, ?MODULE))},

         {"Trigger the projection",
          ?_assertEqual(
            ok,
            khepri:put(
              ?FUNCTION_NAME, PathPattern, Data))},

         {"The projection contains the triggered change",
          ?_assertEqual(Data, ets:lookup_element(?MODULE, PathPattern, 2))}]
      }]}.

trigger_simple_projection_on_pattern_test_() ->
    ProjectFun = fun(Path, Payload) -> {Path, Payload} end,
    PathPattern = [stock, wood, ?KHEPRI_WILDCARD_STAR],
    Path1 = [stock, wood, <<"oak">>],
    Path2 = [stock, wood, <<"birch">>],
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [{inorder,
        [{"Register the projection",
          ?_test(
              begin
                  Projection = khepri_projection:new(?MODULE, ProjectFun),
                  ?assertEqual(
                    ok,
                    khepri:register_projection(
                      ?FUNCTION_NAME, PathPattern, Projection))
              end)},

         {"Trigger the projection",
          fun() ->
                  ?assertEqual(ok, khepri:put(?FUNCTION_NAME, Path1, 80)),
                  ?assertEqual(ok, khepri:put(?FUNCTION_NAME, Path2, 50))
          end},

         {"The projection contains the triggered changes",
          fun() ->
                  ?assertEqual(80, ets:lookup_element(?MODULE, Path1, 2)),
                  ?assertEqual(50, ets:lookup_element(?MODULE, Path2, 2))
          end}]
      }]}.

dont_trigger_simple_projection_on_unrelated_pattern_test_() ->
    ProjectFun = fun(Path, Payload) -> {Path, Payload} end,
    PathPattern = [stock, wood, ?KHEPRI_WILDCARD_STAR],
    Path1 = [stock, metal, <<"iron">>],
    Path2 = [stock, wood, <<"oak">>, by_origin],
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [{inorder,
        [{"Register the projection",
          ?_test(
              begin
                  Projection = khepri_projection:new(?MODULE, ProjectFun),
                  ?assertEqual(
                    ok,
                    khepri:register_projection(
                      ?FUNCTION_NAME, PathPattern, Projection))
              end)},

         {"Trigger the projection",
          fun() ->
                  ?assertEqual(ok, khepri:put(?FUNCTION_NAME, Path1, 80)),
                  ?assertEqual(ok, khepri:put(?FUNCTION_NAME, Path2, 50))
          end},

         {"The projection contains the triggered changes",
          fun() ->
                  ?assertError(badarg, ets:lookup_element(?MODULE, Path1, 2)),
                  ?assertError(badarg, ets:lookup_element(?MODULE, Path2, 2))
          end}]
      }]}.

trigger_simple_projection_on_compiled_pattern_test_() ->
    ProjectFun = fun(Path, Payload) -> {Path, Payload} end,
    Path = [stock, wood, <<"oak">>],
    Data = 100,
    %% This pattern must be compiled in order to to match the data value
    %% correctly. If this test fails, the pattern is not being compiled before
    %% being used to check paths.
    PathPattern = [stock, wood,
                   #if_data_matches{pattern = '$1',
                                    conditions = [{is_integer, '$1'}]}],
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [{inorder,
        [{"Register the projection",
          ?_test(
              begin
                  Projection = khepri_projection:new(?MODULE, ProjectFun),
                  ?assertEqual(
                    ok,
                    khepri:register_projection(
                      ?FUNCTION_NAME, PathPattern, Projection))
              end)},

         {"Trigger the projection",
          ?_assertEqual(
            ok,
            khepri:put(
              ?FUNCTION_NAME, Path, Data))},

         {"The projection contains the triggered change",
          ?_assertEqual(Data, ets:lookup_element(?MODULE, Path, 2))}]
      }]}.

projections_skip_sprocs_test_() ->
    ProjectFun = fun(Path, Payload) -> {Path, Payload} end,
    PathPattern = [stock, wood, <<"oak">>],
    Data = fun() -> return_value end,
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [{inorder,
        [{"Register the projection",
          ?_test(
              begin
                  Projection = khepri_projection:new(?MODULE, ProjectFun),
                  ?assertEqual(
                    ok,
                    khepri:register_projection(
                      ?FUNCTION_NAME, PathPattern, Projection))
              end)},

         {"Store the stored procedure",
          ?_assertEqual(
            ok,
            khepri:put(
              ?FUNCTION_NAME, PathPattern, Data))},

         {"Call the stored procedure",
          ?_assertEqual(
            return_value,
            khepri:run_sproc(
              ?FUNCTION_NAME, PathPattern, []))},

         {"The projection does not contain the triggered change",
          ?_assertEqual([], ets:lookup(?MODULE, PathPattern))}]
      }]}.

simple_projection_follows_updates_and_deletes_test_() ->
    ProjectFun = fun(Path, Payload) -> {Path, Payload} end,
    PathPattern = [stock, wood, ?KHEPRI_WILDCARD_STAR],
    Path = [stock, wood, <<"oak">>],
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [{inorder,
        [{"Register the projection",
          ?_test(
              begin
                  Projection = khepri_projection:new(?MODULE, ProjectFun),
                  ?assertEqual(
                    ok,
                    khepri:register_projection(
                      ?FUNCTION_NAME, PathPattern, Projection))
              end)},

         {"The projection follows creations",
          ?_test(
              begin
                  ?assertEqual(ok, khepri:put(?FUNCTION_NAME, Path, 80)),
                  ?assertEqual(80, ets:lookup_element(?MODULE, Path, 2))
              end)},

         {"The projection follows updates",
          ?_test(
              begin
                  ?assertEqual(ok, khepri:put(?FUNCTION_NAME, Path, 50)),
                  ?assertEqual(50, ets:lookup_element(?MODULE, Path, 2)),
                  ?assertEqual(ok, khepri:put(?FUNCTION_NAME, Path, 50)),
                  ?assertEqual(50, ets:lookup_element(?MODULE, Path, 2)),
                  ?assertEqual(ok, khepri:put(?FUNCTION_NAME, Path, 60)),
                  ?assertEqual(60, ets:lookup_element(?MODULE, Path, 2))
              end)},

         {"The projection follows deletions",
          ?_test(
              begin
                  ?assertEqual(ok, khepri:delete(?FUNCTION_NAME, Path)),
                  ?assertEqual([], ets:lookup(?MODULE, Path))
              end)}]
      }]}.

extended_project_fun(
  Table, Path, #{data := OldPayload}, #{data := NewPayload}) ->
    Deletions = sets:subtract(OldPayload, NewPayload),
    Insertions = sets:subtract(NewPayload, OldPayload),
    sets:fold(fun(Record, _Acc) ->
                      ets:delete_object(Table, {Path, Record})
              end, [], Deletions),
    ets:insert(Table, [{Path, Record} || Record <- sets:to_list(Insertions)]);
extended_project_fun(Table, Path, _OldProps, #{data := NewPayload}) ->
    ets:insert(Table, [{Path, Record} || Record <- sets:to_list(NewPayload)]);
extended_project_fun(
  Table, Path, #{data := _OldPayload}, _NewProps) ->
    ets:delete(Table, Path);
extended_project_fun(_Table, _Path, OldProps, NewProps) ->
    throw({OldProps, NewProps}),
    ok.

trigger_extended_projection_on_path_test_() ->
    ProjectFun = fun extended_project_fun/4,
    PathPattern = [stock, wood, <<"oak">>],
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [{inorder,
        [{"Register the projection",
          ?_test(
              begin
                  Projection = khepri_projection:new(
                                 ?MODULE, ProjectFun, #{type => bag}),
                  ?assertEqual(
                    ok,
                    khepri:register_projection(
                      ?FUNCTION_NAME, PathPattern, Projection))
              end)},

         {"Trigger a create in the projection",
          ?_assertEqual(
            ok,
            khepri:put(
              ?FUNCTION_NAME, PathPattern, sets:from_list([a, b, c])))},

         {"The projection contains the created records",
          ?_test(
              begin
                  Expected = sets:from_list([a, b, c]),
                  Records = ets:lookup_element(?MODULE, PathPattern, 2),
                  Actual = sets:from_list(Records),
                  ?assertEqual(Expected, Actual)
              end)},

         {"Trigger an update in the projection",
          ?_assertEqual(
            ok,
            khepri:put(
              ?FUNCTION_NAME, PathPattern, sets:from_list([b, d])))},

         {"The projection contains the updated records",
          ?_test(
              begin
                  Expected = sets:from_list([b, d]),
                  Records = ets:lookup_element(?MODULE, PathPattern, 2),
                  Actual = sets:from_list(Records),
                  ?assertEqual(Expected, Actual)
              end)},

         {"Trigger a delete in the projection",
          ?_assertEqual(
            ok,
            khepri:delete(?FUNCTION_NAME, PathPattern))},

         {"The projection is empty",
          ?_assertEqual([], ets:tab2list(?MODULE))}]
      }]}.

duplicate_registrations_give_an_error_test_() ->
    ProjectFun = fun(Path, Payload) -> {Path, Payload} end,
    PathPattern = [stock, wood, <<"oak">>],
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [{inorder,
        [{"Register the projection",
          ?_test(
              begin
                  Projection = khepri_projection:new(?MODULE, ProjectFun),
                  ?assertEqual(
                    ok,
                    khepri:register_projection(
                      ?FUNCTION_NAME, PathPattern, Projection))
              end)},

         {"Re-register the same projection",
          ?_test(
              begin
                  Projection = khepri_projection:new(?MODULE, ProjectFun),
                  ?assertEqual(
                    {error, ?khepri_error(projection_already_exists,
                                          #{name => ?MODULE})},
                    khepri:register_projection(
                      ?FUNCTION_NAME, PathPattern, Projection))
              end)}]
      }]}.

projection_table_is_destroyed_on_cluster_shutdown_test() ->
    Priv = test_ra_server_helpers:setup(?FUNCTION_NAME),

    ProjectFun = fun(Path, Payload) -> {Path, Payload} end,
    Projection = khepri_projection:new(?MODULE, ProjectFun),
    PathPattern = [stock, wood, <<"oak">>],

    ?assertEqual(
      ok, khepri:register_projection(?FUNCTION_NAME, PathPattern, Projection)),
    ?assertNotEqual(undefined, ets:info(?MODULE)),

    test_ra_server_helpers:cleanup(Priv),

    ?assertEqual(undefined, ets:info(?MODULE)).

unknown_options_are_rejected_test() ->
    ProjectionName = ?FUNCTION_NAME,
    ProjectFun = fun(Path, Data) -> {Path, Data} end,
    %% `ordered_bag' is not a real ets table type.
    Options1 = #{type => ordered_bag, read_concurrency => true},
    ?assertThrow(
      {unexpected_option, type, ordered_bag},
      khepri_projection:new(ProjectionName, ProjectFun, Options1)),
    %% `bag' is a valid ets table type but is not valid for use with
    %% simple projection funs.
    Options2 = #{type => bag},
    ?assertThrow(
      {unexpected_option, type, bag},
      khepri_projection:new(ProjectionName, ProjectFun, Options2)).

registration_triggers_projections_retroactively_test_() ->
    ProjectFun = fun(Path, Payload) -> {Path, Payload} end,
    PathPattern = [stock, wood, <<"oak">>],
    Data = 100,
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [{inorder,
        [{"Store data in the projection's path",
          ?_assertEqual(
              ok,
              khepri:put(?FUNCTION_NAME, PathPattern, Data))},

         {"Register the projection",
          ?_test(
              begin
                  Projection = khepri_projection:new(?MODULE, ProjectFun),
                  ?assertEqual(
                    ok,
                    khepri:register_projection(
                      ?FUNCTION_NAME, PathPattern, Projection))
              end)},

         {"The projection contains the expected record",
          ?_assertEqual(Data, ets:lookup_element(?MODULE, PathPattern, 2))}]
      }]}.

projection_which_errors_does_not_cause_machine_to_exit_test_() ->
    %% Path != Payload, so this will give a function-clause error.
    ProjectFun = fun(P, P) -> P end,
    PathPattern = [stock, wood, <<"oak">>],
    Data = 100,
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [{inorder,
        [{"Register the projection",
          ?_test(
              begin
                  Projection = khepri_projection:new(?MODULE, ProjectFun),
                  ?assertEqual(
                    ok,
                    khepri:register_projection(
                      ?FUNCTION_NAME, PathPattern, Projection))
              end)},

         {"Trigger the projection",
          ?_test(
              begin
                  Log = helpers:capture_log(
                          fun() ->
                                  ?assertEqual(
                                    ok,
                                    khepri:put(
                                      ?FUNCTION_NAME, PathPattern, Data))
                          end),
                  ?assertSubString(<<"Failed to execute simple projection "
                                     "function">>, Log),
                  ?assertSubString(list_to_binary(?MODULE_STRING), Log),
                  ?assertSubString(<<"no function clause matching">>, Log)
              end)},

         {"The projection does not contain the triggered change",
          ?_assertEqual(false, ets:member(?MODULE, PathPattern))},

         {"The store contains the triggered change",
          ?_assertEqual({ok, Data}, khepri:get(?FUNCTION_NAME, PathPattern))}]
      }]}.

projection_which_returns_non_tuple_does_not_cause_machine_to_exit_test_() ->
    PathPattern = [stock, wood, <<"oak">>],
    Data = not_a_record,
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [{inorder,
        [{"Register the projection",
          ?_test(
              begin
                  Projection = khepri_projection:new(?MODULE, copy),
                  ?assertEqual(
                    ok,
                    khepri:register_projection(
                      ?FUNCTION_NAME, PathPattern, Projection))
              end)},
         {"Trigger the projection",
          ?_test(
              begin
                  Log = helpers:capture_log(
                          fun() ->
                                  ?assertEqual(
                                    ok,
                                    khepri:put(
                                      ?FUNCTION_NAME, PathPattern, Data))
                          end),
                  ?assertSubString(<<"Failed to insert record into "
                                     "ETS table">>, Log),
                  ?assertSubString(list_to_binary(?MODULE_STRING), Log),
                  ?assertSubString(<<"bad argument">>, Log)
              end)},
         {"The projection does not contain the triggered change",
          ?_assertEqual([], ets:tab2list(?MODULE))}]}]}.

delete_removes_entries_recursively_test_() ->
    ProjectFun = fun(Path, Payload) -> {Path, Payload} end,
    PathPattern = [stock,
                   ?KHEPRI_WILDCARD_STAR,
                   <<"maple">>,
                   ?KHEPRI_WILDCARD_STAR],
    Path1 = [stock, wood, <<"maple">>, <<"log">>],
    Path2 = [stock, food, <<"maple">>, <<"syrup">>],
    Path3 = [stock, food, <<"maple">>, <<"bacon">>],
    Data = 100,
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [{inorder,
        [{"Register the projection",
          ?_test(
            begin
                Projection = khepri_projection:new(?MODULE, ProjectFun),
                ?assertEqual(
                  ok,
                  khepri:register_projection(
                    ?FUNCTION_NAME, PathPattern, Projection))
            end)},
         {"Trigger the projection (path 1)",
          ?_assertEqual(
            ok,
            khepri:put(?FUNCTION_NAME, Path1, Data))},
         {"Trigger the projection (path 2)",
          ?_assertEqual(
            ok,
            khepri:put(?FUNCTION_NAME, Path2, Data))},
         {"Trigger the projection (path 3)",
          ?_assertEqual(
            ok,
            khepri:put(?FUNCTION_NAME, Path3, Data))},
         {"List the projection",
          ?_assertEqual(
            lists:sort(
              [{Path1, Data}, {Path2, Data}, {Path3, Data}]),
            lists:sort(ets:tab2list(?MODULE)))},
         {"Delete one of the leaf nodes",
          ?_assertEqual(
            ok,
            khepri:delete(?FUNCTION_NAME, Path3))},
         {"List the projection",
          ?_assertEqual(
            #{Path1 => Data, Path2 => Data},
            maps:from_list(ets:tab2list(?MODULE)))},
         {"Delete a branch of the tree",
          %% All tree nodes in the branch are removed from the tree and all
          %% projection records are removed from the projection table.
          ?_assertEqual(
            ok,
            khepri:delete(?FUNCTION_NAME, [stock, food]))},
         {"List the projection",
          ?_assertEqual(
            [{Path1, Data}],
            ets:tab2list(?MODULE))}]}]}.

trivial_copy_projection_test_() ->
    PathPattern = [stock, wood, ?KHEPRI_WILDCARD_STAR],
    Path1 = [stock, wood, <<"oak">>],
    Path2 = [stock, wood, <<"birch">>],
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [{inorder,
        [{"Register the projection",
          ?_test(
              begin
                  Projection = khepri_projection:new(?MODULE, copy),
                  ?assertEqual(
                    ok,
                    khepri:register_projection(
                      ?FUNCTION_NAME, PathPattern, Projection))
              end)},

         {"Trigger the projection with inserts",
          fun() ->
                  ?assertEqual(
                    ok,
                    khepri:put(?FUNCTION_NAME, Path1, {Path1, 80})),
                  ?assertEqual(
                    ok,
                    khepri:put(?FUNCTION_NAME, Path2, {Path2, 50}))
          end},

         {"The projection contains the triggered changes",
          fun() ->
                  ?assertEqual(80, ets:lookup_element(?MODULE, Path1, 2)),
                  ?assertEqual(50, ets:lookup_element(?MODULE, Path2, 2))
          end},

         {"Trigger the projection with updates",
          fun() ->
                  ?assertEqual(
                    ok,
                    khepri:put(?FUNCTION_NAME, Path1, {Path1, 70})),
                  ?assertEqual(
                    ok,
                    khepri:put(?FUNCTION_NAME, Path2, {Path2, 40}))
          end},

         {"The projection contains the updated records",
          fun() ->
                  ?assertEqual(70, ets:lookup_element(?MODULE, Path1, 2)),
                  ?assertEqual(40, ets:lookup_element(?MODULE, Path2, 2))
          end},

         {"Trigger the projection with a deletion",
          ?_assertEqual(ok, khepri:delete(?FUNCTION_NAME, Path1))},

         {"The projection contains the expected records",
          fun() ->
                  ?assertEqual(false, ets:member(?MODULE, Path1)),
                  ?assertEqual(40, ets:lookup_element(?MODULE, Path2, 2))
          end}]
      }]}.

projection_with_custom_horus_options_test_() ->
    PathPattern = [stock, wood, ?KHEPRI_WILDCARD_STAR],
    Path = [stock, wood, <<"oak">>],
    Data = 100,
    ProjectFun = fun(Path0, Payload) ->
                         {Path0, Payload, crypto:strong_rand_bytes(1)}
                 end,
    ShouldProcessFunction = fun (crypto, strong_rand_bytes, _A, _From) ->
                                    false;
                                (M, F, A, From) ->
                                    khepri_tx_adv:should_process_function(
                                      M, F, A, From)
                            end,
    Options = #{standalone_fun_options =>
                #{should_process_function => ShouldProcessFunction}},
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [{inorder,
        [{"Register the projection",
          ?_test(
              begin
                  Projection = khepri_projection:new(
                                 ?MODULE, ProjectFun, Options),
                  ?assertEqual(
                    ok,
                    khepri:register_projection(
                      ?FUNCTION_NAME, PathPattern, Projection))
              end)},

         {"Trigger the projection",
          ?_assertEqual(
            ok,
            khepri:put(?FUNCTION_NAME, Path, Data))},

         {"The projection contains the expected record",
          ?_assertMatch(
            [{Path, Data, _}],
            ets:lookup(?MODULE, Path))}]
      }]}.

unregister_projection_test_() ->
    ProjectFun = fun(Path, Payload) -> {Path, Payload} end,
    PathPattern = [stock, wood, <<"oak">>],
    Data = 100,
    ProjectionName1 = projection_1,
    ProjectionName2 = projection_2,
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [{inorder,
        [{"Register projections",
          ?_test(
              begin
                  Projection1 = khepri_projection:new(
                                  ProjectionName1, ProjectFun),
                  ?assertEqual(
                    ok,
                    khepri:register_projection(
                      ?FUNCTION_NAME, PathPattern, Projection1)),

                  Projection2 = khepri_projection:new(
                                  ProjectionName2, ProjectFun),
                  ?assertEqual(
                    ok,
                    khepri:register_projection(
                      ?FUNCTION_NAME, PathPattern, Projection2))
              end)},

         {"Trigger the projection",
          ?_assertEqual(
            ok,
            khepri:put(
              ?FUNCTION_NAME, PathPattern, Data))},

         {"The projections contain the triggered change",
          ?_test(
              begin
                  ?assertEqual(
                    Data,
                    ets:lookup_element(ProjectionName1, PathPattern, 2)),
                  ?assertEqual(
                    Data,
                    ets:lookup_element(ProjectionName2, PathPattern, 2))
              end)},

         {"Unregister an unknown projection",
          ?_assertEqual(
            {ok, #{}},
            khepri_adv:unregister_projections(?FUNCTION_NAME, [undefined]))},

         {"Unregister one of the projections",
          ?_assertEqual(
            {ok, #{ProjectionName1 => PathPattern}},
            khepri_adv:unregister_projections(
              ?FUNCTION_NAME, [ProjectionName1]))},

         {"The store no longer contains that projection",
          ?_assertEqual(
            false,
            khepri:has_projection(?FUNCTION_NAME, ProjectionName1))},

         {"The projection table no longer exists",
          ?_assertEqual(undefined, ets:info(ProjectionName1))},

         {"Unregistering the projection again is a no-op",
          ?_assertEqual(
            {ok, #{}},
            khepri_adv:unregister_projections(
              ?FUNCTION_NAME, [ProjectionName1]))},

         {"The store still contains the other projection",
          ?_assertEqual(
            true,
            khepri:has_projection(?FUNCTION_NAME, ProjectionName2))},

         {"Unregistering a projection without an ETS table is ok",
          ?_test(
              begin
                  true = ets:delete(ProjectionName2),
                  ?assertEqual(
                    {ok, #{ProjectionName2 => PathPattern}},
                    khepri_adv:unregister_projections(
                      ?FUNCTION_NAME, [ProjectionName2]))
              end)},

         {"The store no longer contains that projection",
          ?_assertEqual(
            false,
            khepri:has_projection(?FUNCTION_NAME, ProjectionName1))},

         {"That projection table no longer exists",
          ?_assertEqual(undefined, ets:info(ProjectionName2))}]
      }]}.

unregister_all_projections_test_() ->
    ProjectFun = fun(Path, Payload) -> {Path, Payload} end,
    PathPattern = [stock, wood, <<"oak">>],
    Data = 100,
    ProjectionName1 = projection_1,
    ProjectionName2 = projection_2,
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [{inorder,
        [{"Unregister all projections",
          ?_assertEqual(
            {ok, #{}},
            khepri_adv:unregister_projections(?FUNCTION_NAME, all))},

         {"Register projections",
          ?_test(
              begin
                  Projection1 = khepri_projection:new(
                                  ProjectionName1, ProjectFun),
                  ?assertEqual(
                    ok,
                    khepri:register_projection(
                      ?FUNCTION_NAME, PathPattern, Projection1)),

                  Projection2 = khepri_projection:new(
                                  ProjectionName2, ProjectFun),
                  ?assertEqual(
                    ok,
                    khepri:register_projection(
                      ?FUNCTION_NAME, PathPattern, Projection2))
              end)},

         {"Trigger the projections",
          ?_assertEqual(
            ok,
            khepri:put(?FUNCTION_NAME, PathPattern, Data))},

         {"The projections contain the triggered change",
          ?_test(
              begin
                  ?assertEqual(
                    Data,
                    ets:lookup_element(ProjectionName1, PathPattern, 2)),
                  ?assertEqual(
                    Data,
                    ets:lookup_element(ProjectionName2, PathPattern, 2))
              end)},

         {"Unregister the projections",
          ?_assertEqual(
            {ok, #{ProjectionName1 => PathPattern,
                   ProjectionName2 => PathPattern}},
            khepri_adv:unregister_projections(?FUNCTION_NAME, all))},

         {"The store no longer contains the projections",
          ?_test(
              begin
                  ?assertEqual(
                      false,
                      khepri:has_projection(?FUNCTION_NAME, ProjectionName1)),
                  ?assertEqual(
                      false,
                      khepri:has_projection(?FUNCTION_NAME, ProjectionName2))
              end)},

         {"The projection tables no longer exist",
          ?_test(
              begin
                  ?assertEqual(undefined, ets:info(ProjectionName1)),
                  ?assertEqual(undefined, ets:info(ProjectionName2))
              end)},

         {"Unregistering the projections again is ok",
          ?_assertEqual(
            {ok, #{}},
            khepri_adv:unregister_projections(?FUNCTION_NAME, all))}]
      }]}.

old_unregister_projection_command_accepted_test() ->
    S0 = khepri_machine:init(?MACH_PARAMS([])),
    Command = #unregister_projection{name = ?FUNCTION_NAME},
    ?assertMatch(
       {_S1, {ok, #{}}, _SE},
       khepri_machine:apply(?META, Command, S0)).

trigger_projection_via_a_transaction_test_() ->
    ProjectFun = fun(Path, Payload) -> {Path, Payload} end,
    PathPattern = [stock, wood, <<"oak">>],
    Data1 = 100,
    Data2 = 200,
    {setup,
     fun() -> test_ra_server_helpers:setup(?FUNCTION_NAME) end,
     fun(Priv) -> test_ra_server_helpers:cleanup(Priv) end,
     [{inorder,
        [{"Register the projection",
          ?_test(
              begin
                  Projection = khepri_projection:new(?MODULE, ProjectFun),
                  ?assertEqual(
                    ok,
                    khepri:register_projection(
                      ?FUNCTION_NAME, PathPattern, Projection))
              end)},

         {"Trigger the projection with a non-transaction command",
          ?_assertEqual(
            ok,
            khepri:put(
              ?FUNCTION_NAME, PathPattern, Data1))},

         {"The projection contains the triggered change",
          ?_assertEqual(Data1, ets:lookup_element(?MODULE, PathPattern, 2))},

         {"Trigger the projection with a transaction",
          ?_assertEqual(
            {ok, ok},
            khepri:transaction(
              ?FUNCTION_NAME,
              fun() ->
                      %% Issue a delete and then a put with the new data. This
                      %% case checks that the side effects which trigger
                      %% projections are accrued in the correct order within a
                      %% transaction.
                      %%
                      %% If the effects were accrued in the wrong order, the
                      %% next assertion would fail: if the effect(s) for delete
                      %% were processed after the put, the record would not
                      %% exist in the table. Instead it should exist and be
                      %% updated to `Data2'.
                      ok = khepri_tx:delete(PathPattern),
                      ok = khepri_tx:put(PathPattern, Data2)
              end))},

         {"The projection contains the triggered change",
          ?_assertEqual(Data2, ets:lookup_element(?MODULE, PathPattern, 2))}]
      }]}.

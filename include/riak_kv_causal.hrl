-record(riak_kv_pending_put, {
          bkey :: {binary(), binary()},
          object :: term(),
          req_id :: non_neg_integer(),
          start_time :: non_neg_integer(),
          options :: list(),
          sender :: term()}).


-record(riak_kv_pending_get, {
          bkey :: {binary(), binary()},
          req_id :: non_neg_integer(),
          sender :: term()}).

-record(riak_kv_put_req_causal, {
          time_stamp :: integer(),
          bkey :: {binary(),binary()},
          object :: term(),
          req_id :: non_neg_integer(),
          start_time :: non_neg_integer(),
          options :: list()}).

-record(riak_kv_get_req_causal, {
          time_stamp :: integer(),
          bkey :: {binary(), binary()},
          req_id :: non_neg_integer()}).


-define(FIXED_N_VAL, 3).
-define(FIXED_W_VAL, 2).
-define(FIXED_R_VAL, 1).
-define(GET_OP_TS_TIMEOUT, infinity).
-define(UPDATE_PROPAGATION_TIMEOUT, infinity).
-define(KV_PUT_REQ_CAUSAL, #riak_kv_put_req_causal).
-define(KV_GET_REQ_CAUSAL, #riak_kv_get_req_causal).
-define(KV_PUT_PENDING, #riak_kv_pending_put).
-define(KV_GET_PENDING, #riak_kv_pending_get).

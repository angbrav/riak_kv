-record(riak_kv_pending_put, {
          time_stamp :: integer(),
          bkey :: {binary(), binary()},
          object :: term(),
          req_id :: non_neg_integer(),
          start_time :: non_neg_integer(),
          options :: list()}).

-define(FIXED_N_VAL, 3).
-define(GET_OP_TS_TIMEOUT, infinity).
-define(UPDATE_PROPAGATION_TIMEOUT, infinity).

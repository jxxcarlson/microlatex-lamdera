module Evergreen.V616.Parser.Expr exposing (..)

import Evergreen.V616.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V616.Parser.Meta.Meta
    | Text String Evergreen.V616.Parser.Meta.Meta
    | Verbatim String String Evergreen.V616.Parser.Meta.Meta

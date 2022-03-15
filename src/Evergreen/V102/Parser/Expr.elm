module Evergreen.V102.Parser.Expr exposing (..)

import Evergreen.V102.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V102.Parser.Meta.Meta
    | Text String Evergreen.V102.Parser.Meta.Meta
    | Verbatim String String Evergreen.V102.Parser.Meta.Meta

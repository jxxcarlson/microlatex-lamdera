module Evergreen.V555.Parser.Expr exposing (..)

import Evergreen.V555.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V555.Parser.Meta.Meta
    | Text String Evergreen.V555.Parser.Meta.Meta
    | Verbatim String String Evergreen.V555.Parser.Meta.Meta

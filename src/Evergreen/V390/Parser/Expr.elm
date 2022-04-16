module Evergreen.V390.Parser.Expr exposing (..)

import Evergreen.V390.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V390.Parser.Meta.Meta
    | Text String Evergreen.V390.Parser.Meta.Meta
    | Verbatim String String Evergreen.V390.Parser.Meta.Meta

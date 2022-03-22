module Evergreen.V147.Parser.Expr exposing (..)

import Evergreen.V147.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V147.Parser.Meta.Meta
    | Text String Evergreen.V147.Parser.Meta.Meta
    | Verbatim String String Evergreen.V147.Parser.Meta.Meta

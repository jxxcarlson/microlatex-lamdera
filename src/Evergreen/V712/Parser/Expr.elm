module Evergreen.V712.Parser.Expr exposing (..)

import Evergreen.V712.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V712.Parser.Meta.Meta
    | Text String Evergreen.V712.Parser.Meta.Meta
    | Verbatim String String Evergreen.V712.Parser.Meta.Meta

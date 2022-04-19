module Evergreen.V416.Parser.Expr exposing (..)

import Evergreen.V416.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V416.Parser.Meta.Meta
    | Text String Evergreen.V416.Parser.Meta.Meta
    | Verbatim String String Evergreen.V416.Parser.Meta.Meta

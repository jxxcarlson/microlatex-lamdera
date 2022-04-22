module Evergreen.V449.Parser.Expr exposing (..)

import Evergreen.V449.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V449.Parser.Meta.Meta
    | Text String Evergreen.V449.Parser.Meta.Meta
    | Verbatim String String Evergreen.V449.Parser.Meta.Meta

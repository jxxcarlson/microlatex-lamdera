module Evergreen.V5.Parser.Expr exposing (..)

import Evergreen.V5.Parser.Token


type Expr
    = Expr String (List Expr) Evergreen.V5.Parser.Token.Meta
    | Text String Evergreen.V5.Parser.Token.Meta
    | Verbatim String String Evergreen.V5.Parser.Token.Meta
    | Error String

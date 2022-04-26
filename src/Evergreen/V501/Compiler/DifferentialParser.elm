module Evergreen.V501.Compiler.DifferentialParser exposing (..)

import Evergreen.V501.Compiler.AbstractDifferentialParser
import Evergreen.V501.Compiler.Acc
import Evergreen.V501.Parser.Block
import Evergreen.V501.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V501.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V501.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V501.Parser.Block.ExpressionBlock) Evergreen.V501.Compiler.Acc.Accumulator

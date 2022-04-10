module Evergreen.V348.Compiler.DifferentialParser exposing (..)

import Evergreen.V348.Compiler.AbstractDifferentialParser
import Evergreen.V348.Compiler.Acc
import Evergreen.V348.Parser.Block
import Evergreen.V348.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V348.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V348.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V348.Parser.Block.ExpressionBlock) Evergreen.V348.Compiler.Acc.Accumulator

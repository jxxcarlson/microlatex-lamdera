module Evergreen.V286.Compiler.DifferentialParser exposing (..)

import Evergreen.V286.Compiler.AbstractDifferentialParser
import Evergreen.V286.Compiler.Acc
import Evergreen.V286.Parser.Block
import Evergreen.V286.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V286.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V286.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V286.Parser.Block.ExpressionBlock) Evergreen.V286.Compiler.Acc.Accumulator

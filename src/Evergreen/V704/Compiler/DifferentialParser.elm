module Evergreen.V704.Compiler.DifferentialParser exposing (..)

import Evergreen.V704.Compiler.AbstractDifferentialParser
import Evergreen.V704.Compiler.Acc
import Evergreen.V704.Parser.Block
import Evergreen.V704.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V704.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V704.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V704.Parser.Block.ExpressionBlock) Evergreen.V704.Compiler.Acc.Accumulator

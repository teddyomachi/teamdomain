/* jslint node: true */

'use strict'
const path = require('path')
// var webpack = require('webpack')
// const HtmlWebpackPlugin = require('html-webpack-plugin')
// const MiniCssExtractPlugin = require('mini-css-extract-plugin')

module.exports = {
    entry: {
        cmus_audio_guide: path.join(path.resolve(__dirname, '/app/javascript/packs/'), 'hello-world-bundle.js')
        // You can add additional entry points if you want
        // grid: __dirname + '/app/grid/app.js'
    },
    module: {
        rules: [
            // {
            //     test: /\.(png|jpg|gif|svg|ico)$/,
            //     loader: 'file-loader',
            //     query: {
            //         outputPath: './img/',
            //         name: '[name].[ext]?[hash]'
            //     }
            // },
            {
                test: /\.jsx?$/,
                use: [{loader: 'babel-loader'}],
                exclude: /node_modules/,
            },
            {
                test: /\.css$/,
                use: [
                    {loader: 'resolve-url-loader'},
                    {loader: 'style-loader'},
                    {loader: 'css-loader', options: {url: true, importLoaders: 2}},
                    {loader: 'postcss-loader'}
                ]
            },
            {
                test: /\.(png|jp(e*)g|svg)$/,
                use: [{
                    loader: 'file-loader',
                    options: {
                        // webpacker.yml のentryと同じにする。 publicPathは/で囲わないと、urlの結合がおかしくなるので注意
                        // （ `url('packsapp/assets/...')` みたいになるし、相対パスだと実行時にちゃんと解決されるかわからん）
                        // publicPath: '/packs/',
                        name: process.env.NODE_ENV === 'production' ? '[path][name]-[hash].[ext]' : '[path][name].[ext]',
                    },
                }]
            }
        ],
        plugins: [new HtmlWebpackPlugin({
            title: 'CustomTitle',
            template: 'index.html', // Load a custom template
            inject: 'body' // Inject all scripts into the body
        }),
            new MiniCssExtractPlugin()]
        // ,
        // output:
        //     {
        //         // options related to how webpack emits results
        //
        //         path: path.join(path.resolve(__dirname, '/public/'), 'webpacks'), // string
        //         // the target directory for all output files
        //         // must be an absolute path (use the Node.js path module)
        //
        //         publicPath:
        //             '/webpacks' // string
        //         // the url to the output directory resolved relative to the HTML page
        //
        //         /* Advanced output configuration (click to show) */
        //     }
    }
}

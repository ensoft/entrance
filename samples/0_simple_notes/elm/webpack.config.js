var path = require('path');

const ExtractTextPlugin = require("extract-text-webpack-plugin");

const extractSass = new ExtractTextPlugin({
    filename: "[name].css",
    disable: process.env.ELM_BUILD_PROD != '1'
});

module.exports = {
  entry: {
    app: [
      './src/index.js'
    ]
  },

  output: {
    path: path.resolve(__dirname + '/dist'),
    filename: '[name].js',
  },

  module: {
    rules: [
      {
        test: /\.html$/,
        exclude: /node_modules/,
        loader:  'file-loader?name=[name].[ext]',
      },
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        /*
         * If we're running a full production build (as in "build_prod -prod"
         * then omit the debugger entirely from the build. Otherwise keep it in.
         */
        use: [
          'elm-hot-loader',
          'elm-webpack-loader?verbose=true&warn=true' +
                    (process.env.NODE_ENV === 'production' ? '' : '&debug=true')
        ]
      }
    ],

    noParse: /\.elm$/,

  },

  plugins: [
      extractSass
  ],

  devServer: {
    inline: true,
    stats: 'errors-only',
    disableHostCheck: true
  },


};

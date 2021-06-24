layer_configs = {}
layer_configs[:uab] = {
  url: 'https://a.tiles.mapbox.com/v4/nymtc-gateway.3b7cb19a/{z}/{x}/{y}.vector.pbf?access_token=pk.eyJ1IjoibnltdGMtZ2F0ZXdheSIsImEiOiJlZjQ2MzEwNzNiMWM2ODVlMGQ3OGIyNTlkNjk4NzhmMyJ9.1rJtLC-sKwDgMuMVXJDKOg',
  name: 'NYMTC_UAB'
}

layer_configs[:census_tract] = {
  url: 'https://a.tiles.mapbox.com/v4/nymtc-gateway.5b4aaa15/{z}/{x}/{y}.vector.pbf?access_token=pk.eyJ1IjoibnltdGMtZ2F0ZXdheSIsImEiOiJlZjQ2MzEwNzNiMWM2ODVlMGQ3OGIyNTlkNjk4NzhmMyJ9.1rJtLC-sKwDgMuMVXJDKOg',
  name: 'NYMTC_CT'
}

layer_configs[:tcc] = {
  url: 'https://a.tiles.mapbox.com/v4/nymtc-gateway.39f433ae/{z}/{x}/{y}.vector.pbf?access_token=pk.eyJ1IjoibnltdGMtZ2F0ZXdheSIsImEiOiJlZjQ2MzEwNzNiMWM2ODVlMGQ3OGIyNTlkNjk4NzhmMyJ9.1rJtLC-sKwDgMuMVXJDKOg',
  name: 'NYMTC_TCC'
}

layer_configs[:taz] = {
  url: 'https://a.tiles.mapbox.com/v4/nymtc-gateway.b1084905/{z}/{x}/{y}.vector.pbf?access_token=pk.eyJ1IjoibnltdGMtZ2F0ZXdheSIsImEiOiJlZjQ2MzEwNzNiMWM2ODVlMGQ3OGIyNTlkNjk4NzhmMyJ9.1rJtLC-sKwDgMuMVXJDKOg',
  name: 'NYMTC_TAZ'
}

layer_configs[:county] = {
  url: 'https://a.tiles.mapbox.com/v4/nymtc-gateway.d8eb5a9b/{z}/{x}/{y}.vector.pbf?access_token=pk.eyJ1IjoibnltdGMtZ2F0ZXdheSIsImEiOiJlZjQ2MzEwNzNiMWM2ODVlMGQ3OGIyNTlkNjk4NzhmMyJ9.1rJtLC-sKwDgMuMVXJDKOg',
  name: 'NYMTC_County'
}

layer_configs[:subregion] = {
  url: 'https://a.tiles.mapbox.com/v4/nymtc-gateway.d0bc7bf7/{z}/{x}/{y}.vector.pbf?access_token=pk.eyJ1IjoibnltdGMtZ2F0ZXdheSIsImEiOiJlZjQ2MzEwNzNiMWM2ODVlMGQ3OGIyNTlkNjk4NzhmMyJ9.1rJtLC-sKwDgMuMVXJDKOg',
  name: 'NYMTC_Subregion'
}

layer_configs[:tmc] = {
  url: 'https://a.tiles.mapbox.com/v4/nymtc-gateway.a9c19da2/{z}/{x}/{y}.vector.pbf?access_token=pk.eyJ1IjoibnltdGMtZ2F0ZXdheSIsImEiOiJlZjQ2MzEwNzNiMWM2ODVlMGQ3OGIyNTlkNjk4NzhmMyJ9.1rJtLC-sKwDgMuMVXJDKOg',
  name: 'NHS_TMC_2013'
}


layer_configs.each do |key, config|
  MapLayer.where(name: config[:name]).first.update(url: config[:url])
end


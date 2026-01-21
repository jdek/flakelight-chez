{
  description = "Template Chez Scheme application.";
  inputs.flakelight-chez.url = "github:accelbread/flakelight-chez";
  outputs = { flakelight-chez, ... }:
    flakelight-chez ./. {
      license = "MIT";
    };
}

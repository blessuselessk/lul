{ den, ... }:
{
  den.aspects.aldair = {
    includes = [ den.batteries.define-user ];

    user = { ... }: {
      description = "Aldair";
      isNormalUser = true;
      group = "users";
    };
  };
}

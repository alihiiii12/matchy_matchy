enum OtpFlow {
  registration,
  passwordReset,
  profilePasswordChange,
  profileUpdate,
}

class OtpVerificationArgs {
  const OtpVerificationArgs({
    required this.email,
    this.flow = OtpFlow.registration,
    this.debugOtp,
  });

  final String email;
  final OtpFlow flow;
  final String? debugOtp;
}

class ResetPasswordArgs {
  const ResetPasswordArgs({
    required this.email,
    required this.resetToken,
  });

  final String email;
  final String resetToken;
}

class ProfileResetPasswordArgs {
  const ProfileResetPasswordArgs({required this.resetToken});

  final String resetToken;
}

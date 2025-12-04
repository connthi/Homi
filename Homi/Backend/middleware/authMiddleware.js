import User from "../models/userModel.js";
import { verifyAccessToken } from "../utils/security.js";
import { HTTP_STATUS } from "../utils/httpStatus.js";

export async function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(HTTP_STATUS.UNAUTHORIZED).json({ message: "Authorization header missing" });
  }

  const token = authHeader.replace("Bearer ", "").trim();

  try {
    const payload = verifyAccessToken(token);
    const user = await User.findById(payload.sub).lean();

    if (!user) {
      return res.status(HTTP_STATUS.UNAUTHORIZED).json({ message: "User not found" });
    }

    req.user = {
      id: user._id.toString(),
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      isAdmin: user.role === "admin"
    };

    next();
  } catch (error) {
    return res.status(HTTP_STATUS.UNAUTHORIZED).json({ message: "Invalid or expired token" });
  }
}

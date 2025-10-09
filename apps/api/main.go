package main

import (
	"fmt"
	"net/http"
	"os"
	"strings"

	"github.com/davidcharbonnier/alacarte-api/controllers"
	"github.com/davidcharbonnier/alacarte-api/utils"
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

func init() {
	if _, err := os.Stat(".env"); err == nil {
		utils.LoadEnvVars()
	}

	// Initialize secure logger
	utils.InitLogger()

	utils.MySQLConnect()
	utils.RunMigrations()
}

// gin code
func main() {
	// Set gin mode from env
	if ginMode, defined := os.LookupEnv("GIN_MODE"); defined {
		gin.SetMode(ginMode)
	} else {
		gin.SetMode("release")
	}

	router := gin.New()
	router.Use(
		gin.LoggerWithConfig(gin.LoggerConfig{
			SkipPaths: []string{"/health"},
		}),
		gin.Recovery(),
	)

	// Set trusted proxies from env
	if proxies, defined := os.LookupEnv("TRUSTED_PROXIES"); defined {
		router.SetTrustedProxies(strings.Split(proxies, ","))
	} else {
		router.SetTrustedProxies(nil)
	}

	// Setup CORS
	router.Use(setupCORS())

	// health
	router.GET("/health", func(c *gin.Context) {
		c.Status(http.StatusOK)
	})

	// Setup authentication routes
	setupAuthRoutes(router)

	// Profile completion (requires partial auth)
	profile := router.Group("/profile")
	profile.Use(utils.RequirePartialAuth())
	{
		profile.POST("/complete", controllers.CompleteProfile)
		profile.GET("/check-display-name", controllers.CheckDisplayNameAvailability)
	}

	// Protected API routes (requires full auth)
	api := router.Group("/api")
	api.Use(utils.RequireAuth())
	{
		// Auth utilities
		auth := api.Group("/auth")
		{
			auth.GET("/check-admin", controllers.CheckAdminStatus)
		}

		// User management
		user := api.Group("/user")
		{
			user.GET("/me", controllers.GetCurrentUser)
			user.PATCH("/me", controllers.UpdateCurrentUser)
			user.DELETE("/me", controllers.DeleteCurrentUser)
		}

		// User discovery
		users := api.Group("/users")
		{
			users.GET("/shareable", controllers.GetShareableUsers)
		}

		// cheese
		cheese := api.Group("/cheese")
		{
			cheese.POST("/new", controllers.CheeseCreate)
			cheese.GET("/all", controllers.CheeseIndex)
			cheese.GET("/:id", controllers.CheeseDetails)
			cheese.PUT("/:id", controllers.CheeseEdit)
			cheese.DELETE("/:id", controllers.CheeseRemove)
		}

		// gin
		ginItem := api.Group("/gin")
		{
			ginItem.POST("/new", controllers.GinCreate)
			ginItem.GET("/all", controllers.GinIndex)
			ginItem.GET("/:id", controllers.GinDetails)
			ginItem.PUT("/:id", controllers.GinEdit)
			ginItem.DELETE("/:id", controllers.GinRemove)
		}

		// rating
		rating := api.Group("/rating")
		{
			rating.POST("/new", controllers.RatingCreate)
			rating.GET("/author/:id", controllers.RatingByAuthor)
			rating.GET("/viewer/:id", controllers.RatingByViewer)
			rating.GET("/:type/:id", controllers.RatingByItem)
			rating.PUT("/:id", controllers.RatingEdit)
			rating.PUT("/:id/share", controllers.RatingShare)
			rating.PUT("/:id/hide", controllers.RatingHide)
			rating.DELETE("/:id", controllers.RatingRemove)

			// Bulk privacy actions
			rating.PUT("/bulk/private", controllers.BulkMakeRatingsPrivate)
			rating.PUT("/bulk/unshare/:userId", controllers.BulkRemoveUserFromShares)
		}

		// Community statistics (anonymous aggregate data)
		stats := api.Group("/stats")
		{
			stats.GET("/community/:type/:id", controllers.GetCommunityStats)
		}
	}

	// Admin routes (requires admin privileges)
	admin := router.Group("/admin")
	admin.Use(utils.RequireAuth(), utils.RequireAdmin())
	{
		// Cheese admin
		cheese := admin.Group("/cheese")
		{
			cheese.GET("/:id/delete-impact", controllers.GetCheeseDeleteImpact)
			cheese.DELETE("/:id", controllers.DeleteCheese)
			cheese.POST("/seed", controllers.SeedCheeses)
			cheese.POST("/validate", controllers.ValidateCheeses)
		}

		// Gin admin
		ginAdmin := admin.Group("/gin")
		{
			ginAdmin.GET("/:id/delete-impact", controllers.GetGinDeleteImpact)
			ginAdmin.DELETE("/:id", controllers.DeleteGin)
			ginAdmin.POST("/seed", controllers.SeedGins)
			ginAdmin.POST("/validate", controllers.ValidateGins)
		}

		// User admin
		users := admin.Group("/users")
		{
			users.GET("/all", controllers.GetAllUsers)
		}

		user := admin.Group("/user")
		{
			user.GET("/:id", controllers.GetUserDetails)
			user.GET("/:id/delete-impact", controllers.GetUserDeleteImpact)
			user.DELETE("/:id", controllers.DeleteUser)
			user.PATCH("/:id/promote", controllers.PromoteUser)
			user.PATCH("/:id/demote", controllers.DemoteUser)
		}
	}

	router.Run()
}

// Setup CORS for frontend integration
func setupCORS() gin.HandlerFunc {
	config := cors.DefaultConfig()

	if origins := os.Getenv("ALLOWED_ORIGINS"); origins != "" {
		config.AllowOrigins = strings.Split(origins, ",")
	} else {
		// Development default
		config.AllowOrigins = []string{
			"http://localhost:3000",
			"http://localhost:8080",
			"http://127.0.0.1:3000",
			"http://127.0.0.1:8080",
		}
	}

	config.AllowHeaders = []string{"Origin", "Content-Type", "Authorization"}
	config.AllowMethods = []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"}
	config.AllowCredentials = true

	return cors.New(config)
}

// Setup auth routes
func setupAuthRoutes(router *gin.Engine) {
	// Google OAuth endpoint
	auth := router.Group("/auth")
	{
		auth.POST("/google", controllers.GoogleOAuthExchange)
	}

	// Display OAuth configuration
	fmt.Println("🔐 Google OAuth enabled")
	fmt.Println("   • OAuth endpoint: /auth/google")
	fmt.Println("   • Token validation: Google API servers")

	// Only show client ID in development mode
	if gin.Mode() == gin.DebugMode {
		fmt.Printf("   • Client ID: %s\n", os.Getenv("GOOGLE_CLIENT_ID"))
	} else {
		fmt.Println("   • Client ID: [configured]")
	}
}

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
	utils.InitStorageClient()
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

	// Set max upload size for image uploads (5MB)
	router.MaxMultipartMemory = 5 << 20

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
			// Image management
			cheese.POST("/:id/image", func(c *gin.Context) {
				c.Params = append(c.Params, gin.Param{Key: "itemType", Value: "cheese"})
				controllers.UploadItemImage(c)
			})
			cheese.DELETE("/:id/image", func(c *gin.Context) {
				c.Params = append(c.Params, gin.Param{Key: "itemType", Value: "cheese"})
				controllers.DeleteItemImage(c)
			})
		}

		// gin
		ginItem := api.Group("/gin")
		{
			ginItem.POST("/new", controllers.GinCreate)
			ginItem.GET("/all", controllers.GinIndex)
			ginItem.GET("/:id", controllers.GinDetails)
			ginItem.PUT("/:id", controllers.GinEdit)
			ginItem.DELETE("/:id", controllers.GinRemove)
			// Image management
			ginItem.POST("/:id/image", func(c *gin.Context) {
				c.Params = append(c.Params, gin.Param{Key: "itemType", Value: "gin"})
				controllers.UploadItemImage(c)
			})
			ginItem.DELETE("/:id/image", func(c *gin.Context) {
				c.Params = append(c.Params, gin.Param{Key: "itemType", Value: "gin"})
				controllers.DeleteItemImage(c)
			})
		}

		// wine
		wineItem := api.Group("/wine")
		{
			wineItem.POST("/new", controllers.WineCreate)
			wineItem.GET("/all", controllers.WineIndex)
			wineItem.GET("/:id", controllers.WineDetails)
			wineItem.PUT("/:id", controllers.WineEdit)
			wineItem.DELETE("/:id", controllers.WineRemove)
			// Image management
			wineItem.POST("/:id/image", func(c *gin.Context) {
				c.Params = append(c.Params, gin.Param{Key: "itemType", Value: "wine"})
				controllers.UploadItemImage(c)
			})
			wineItem.DELETE("/:id/image", func(c *gin.Context) {
				c.Params = append(c.Params, gin.Param{Key: "itemType", Value: "wine"})
				controllers.DeleteItemImage(c)
			})
		}

		// coffee
		coffee := api.Group("/coffee")
		{
			coffee.POST("/new", controllers.CoffeeCreate)
			coffee.GET("/all", controllers.CoffeeIndex)
			coffee.GET("/:id", controllers.CoffeeDetails)
			coffee.PUT("/:id", controllers.CoffeeEdit)
			coffee.DELETE("/:id", controllers.CoffeeRemove)
			// Image management
			coffee.POST("/:id/image", func(c *gin.Context) {
				c.Params = append(c.Params, gin.Param{Key: "itemType", Value: "coffee"})
				controllers.UploadItemImage(c)
			})
			coffee.DELETE("/:id/image", func(c *gin.Context) {
				c.Params = append(c.Params, gin.Param{Key: "itemType", Value: "coffee"})
				controllers.DeleteItemImage(c)
			})
		}

		// chili-sauce
		chiliSauce := api.Group("/chili-sauce")
		{
			chiliSauce.POST("/new", controllers.ChiliSauceCreate)
			chiliSauce.GET("/all", controllers.ChiliSauceIndex)
			chiliSauce.GET("/:id", controllers.ChiliSauceDetails)
			chiliSauce.PUT("/:id", controllers.ChiliSauceEdit)
			chiliSauce.DELETE("/:id", controllers.ChiliSauceRemove)
			// Image management
			chiliSauce.POST("/:id/image", func(c *gin.Context) {
				c.Params = append(c.Params, gin.Param{Key: "itemType", Value: "chili-sauce"})
				controllers.UploadItemImage(c)
			})
			chiliSauce.DELETE("/:id/image", func(c *gin.Context) {
				c.Params = append(c.Params, gin.Param{Key: "itemType", Value: "chili-sauce"})
				controllers.DeleteItemImage(c)
			})
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

		// Wine admin
		wineAdmin := admin.Group("/wine")
		{
			wineAdmin.GET("/:id/delete-impact", controllers.GetWineDeleteImpact)
			wineAdmin.DELETE("/:id", controllers.DeleteWine)
			wineAdmin.POST("/seed", controllers.SeedWines)
			wineAdmin.POST("/validate", controllers.ValidateWines)
		}

		// Coffee admin
		coffeeAdmin := admin.Group("/coffee")
		{
			coffeeAdmin.GET("/:id/delete-impact", controllers.GetCoffeeDeleteImpact)
			coffeeAdmin.DELETE("/:id", controllers.DeleteCoffee)
			coffeeAdmin.POST("/seed", controllers.SeedCoffees)
			coffeeAdmin.POST("/validate", controllers.ValidateCoffees)
		}

		// Chili Sauce admin
		chiliSauceAdmin := admin.Group("/chili-sauce")
		{
			chiliSauceAdmin.GET("/:id/delete-impact", controllers.GetChiliSauceDeleteImpact)
			chiliSauceAdmin.DELETE("/:id", controllers.DeleteChiliSauce)
			chiliSauceAdmin.POST("/seed", controllers.SeedChiliSauces)
			chiliSauceAdmin.POST("/validate", controllers.ValidateChiliSauces)
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

/**
 * Kingsauna Analytics Tracker
 * Tracks page views, events, and user interactions
 */

class KingsaunaAnalytics {
    constructor(supabaseClient) {
        this.supabase = supabaseClient;
        this.sessionId = this.getOrCreateSessionId();
        this.visitorId = this.getOrCreateVisitorId();
        this.pageViewId = null;
        this.pageLoadTime = Date.now();
        this.scrollDepth = 0;
        this.interactionCount = 0;
        
        this.init();
    }
    
    // ==========================================
    // INITIALIZATION
    // ==========================================
    
    init() {
        // Track page view immediately
        this.trackPageView();
        
        // Set up event listeners
        this.setupScrollTracking();
        this.setupInteractionTracking();
        this.setupCTATracking();
        this.setupLinkTracking();
        
        // Track time on page before leaving
        this.setupBeforeUnload();
        
        console.log('📊 Kingsauna Analytics initialized', {
            sessionId: this.sessionId,
            visitorId: this.visitorId
        });
    }
    
    // ==========================================
    // SESSION & VISITOR MANAGEMENT
    // ==========================================
    
    getOrCreateSessionId() {
        let sessionId = sessionStorage.getItem('ks_session_id');
        if (!sessionId) {
            sessionId = 'sess_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
            sessionStorage.setItem('ks_session_id', sessionId);
        }
        return sessionId;
    }
    
    getOrCreateVisitorId() {
        let visitorId = localStorage.getItem('ks_visitor_id');
        if (!visitorId) {
            visitorId = 'visitor_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
            localStorage.setItem('ks_visitor_id', visitorId);
        }
        return visitorId;
    }
    
    // ==========================================
    // PAGE VIEW TRACKING
    // ==========================================
    
    async trackPageView() {
        const urlParams = new URLSearchParams(window.location.search);
        
        const pageData = {
            session_id: this.sessionId,
            visitor_id: this.visitorId,
            page_url: window.location.href,
            page_title: document.title,
            page_path: window.location.pathname,
            referrer: document.referrer || null,
            utm_source: urlParams.get('utm_source'),
            utm_medium: urlParams.get('utm_medium'),
            utm_campaign: urlParams.get('utm_campaign'),
            utm_content: urlParams.get('utm_content'),
            utm_term: urlParams.get('utm_term'),
            user_agent: navigator.userAgent,
            device_type: this.getDeviceType(),
            browser: this.getBrowser(),
            os: this.getOS(),
            screen_width: window.screen.width,
            screen_height: window.screen.height
        };
        
        try {
            const { data, error } = await this.supabase
                .from('page_visitors')
                .insert([pageData])
                .select();
            
            if (error) {
                console.error('❌ Page view tracking error:', error);
            } else if (data && data[0]) {
                this.pageViewId = data[0].id;
                console.log('✅ Page view tracked:', data[0].id);
            }
        } catch (err) {
            console.error('❌ Page view tracking failed:', err);
        }
    }
    
    // ==========================================
    // EVENT TRACKING
    // ==========================================
    
    async trackEvent(eventType, eventData = {}) {
        const event = {
            session_id: this.sessionId,
            visitor_id: this.visitorId,
            event_type: eventType,
            event_category: eventData.category || 'general',
            event_label: eventData.label || null,
            event_value: eventData.value || null,
            page_url: window.location.href,
            page_path: window.location.pathname,
            element_id: eventData.elementId || null,
            element_text: eventData.elementText || null,
            element_position: eventData.position || null,
            metadata: eventData.metadata || null
        };
        
        try {
            const { error } = await this.supabase
                .from('user_events')
                .insert([event]);
            
            if (error) {
                console.error('❌ Event tracking error:', error);
            } else {
                console.log('✅ Event tracked:', eventType);
            }
        } catch (err) {
            console.error('❌ Event tracking failed:', err);
        }
    }
    
    // ==========================================
    // FUNNEL TRACKING
    // ==========================================
    
    async trackFunnelStep(stepName, stepNumber, funnelType = null, metadata = {}) {
        const funnelData = {
            session_id: this.sessionId,
            visitor_id: this.visitorId,
            step_name: stepName,
            step_number: stepNumber,
            funnel_type: funnelType,
            page_url: window.location.href,
            metadata: metadata
        };
        
        try {
            await this.supabase
                .from('funnel_steps')
                .insert([funnelData]);
            
            console.log('✅ Funnel step tracked:', stepName);
        } catch (err) {
            console.error('❌ Funnel tracking failed:', err);
        }
    }
    
    // ==========================================
    // SCROLL TRACKING
    // ==========================================
    
    setupScrollTracking() {
        let ticking = false;
        
        window.addEventListener('scroll', () => {
            if (!ticking) {
                window.requestAnimationFrame(() => {
                    this.updateScrollDepth();
                    ticking = false;
                });
                ticking = true;
            }
        });
    }
    
    updateScrollDepth() {
        const windowHeight = window.innerHeight;
        const documentHeight = document.documentElement.scrollHeight;
        const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
        
        const scrollPercentage = Math.round((scrollTop / (documentHeight - windowHeight)) * 100);
        
        if (scrollPercentage > this.scrollDepth) {
            this.scrollDepth = scrollPercentage;
        }
    }
    
    // ==========================================
    // INTERACTION TRACKING
    // ==========================================
    
    setupInteractionTracking() {
        ['click', 'keypress', 'mousemove', 'scroll'].forEach(eventType => {
            document.addEventListener(eventType, () => {
                this.interactionCount++;
            }, { once: false, passive: true });
        });
    }
    
    // ==========================================
    // CTA BUTTON TRACKING
    // ==========================================
    
    setupCTATracking() {
        document.querySelectorAll('[class*="cta-"]').forEach(button => {
            button.addEventListener('click', (e) => {
                const buttonText = e.target.textContent.trim();
                const buttonClass = e.target.className;
                const buttonId = e.target.id || 'no-id';
                
                this.trackEvent('cta_click', {
                    category: 'conversion',
                    label: buttonId,
                    elementText: buttonText,
                    elementId: buttonId,
                    metadata: { buttonClass }
                });
            });
        });
    }
    
    // ==========================================
    // LINK TRACKING
    // ==========================================
    
    setupLinkTracking() {
        document.querySelectorAll('a[href]').forEach(link => {
            link.addEventListener('click', (e) => {
                const linkText = e.target.textContent.trim();
                const linkHref = e.target.href;
                const isExternal = !linkHref.includes(window.location.hostname);
                
                this.trackEvent('link_click', {
                    category: isExternal ? 'external' : 'internal',
                    label: linkHref,
                    elementText: linkText,
                    metadata: { href: linkHref, external: isExternal }
                });
            });
        });
    }
    
    // ==========================================
    // UPDATE PAGE VIEW ON EXIT
    // ==========================================
    
    setupBeforeUnload() {
        window.addEventListener('beforeunload', () => {
            this.updatePageViewOnExit();
        });
        
        // Also update periodically (every 30 seconds)
        setInterval(() => {
            this.updatePageViewOnExit();
        }, 30000);
    }
    
    async updatePageViewOnExit() {
        if (!this.pageViewId) return;
        
        const timeOnPage = Math.round((Date.now() - this.pageLoadTime) / 1000);
        
        try {
            await this.supabase
                .from('page_visitors')
                .update({
                    time_on_page_seconds: timeOnPage,
                    scroll_depth: this.scrollDepth,
                    interactions_count: this.interactionCount
                })
                .eq('id', this.pageViewId);
        } catch (err) {
            console.error('❌ Failed to update page view:', err);
        }
    }
    
    // ==========================================
    // DEVICE DETECTION UTILITIES
    // ==========================================
    
    getDeviceType() {
        const ua = navigator.userAgent;
        if (/(tablet|ipad|playbook|silk)|(android(?!.*mobi))/i.test(ua)) {
            return 'tablet';
        }
        if (/Mobile|Android|iP(hone|od)|IEMobile|BlackBerry|Kindle|Silk-Accelerated|(hpw|web)OS|Opera M(obi|ini)/.test(ua)) {
            return 'mobile';
        }
        return 'desktop';
    }
    
    getBrowser() {
        const ua = navigator.userAgent;
        if (ua.includes('Firefox')) return 'Firefox';
        if (ua.includes('Edg')) return 'Edge';
        if (ua.includes('Chrome')) return 'Chrome';
        if (ua.includes('Safari')) return 'Safari';
        if (ua.includes('Opera')) return 'Opera';
        return 'Unknown';
    }
    
    getOS() {
        const ua = navigator.userAgent;
        if (ua.includes('Win')) return 'Windows';
        if (ua.includes('Mac')) return 'MacOS';
        if (ua.includes('Linux')) return 'Linux';
        if (ua.includes('Android')) return 'Android';
        if (ua.includes('iOS') || ua.includes('iPhone') || ua.includes('iPad')) return 'iOS';
        return 'Unknown';
    }
}

// ==========================================
// EXPORT FOR USE
// ==========================================

// Initialize analytics when Supabase is ready
window.initKingsaunaAnalytics = function(supabaseClient) {
    window.ksAnalytics = new KingsaunaAnalytics(supabaseClient);
    return window.ksAnalytics;
};

